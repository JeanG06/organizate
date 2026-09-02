/* ============================================================
   ORGANIZATE - App principal (v2 · Fase 1)
   Calendario-tablero de posits con fichas recurrentes.
   ============================================================ */

// ---------- Verificacion de config ----------
if (!SUPABASE_URL || SUPABASE_URL === 'SIN_CONFIGURAR' || !SUPABASE_ANON_KEY || SUPABASE_ANON_KEY === 'SIN_CONFIGURAR') {
  alert('⚠️ Falta configurar Supabase.\nCopia el archivo js/env.js (crea una plantilla) y pega tu SUPABASE_URL y SUPABASE_ANON_KEY reales.');
}

const sbClient = window.supabase.createClient(SUPABASE_URL, SUPABASE_ANON_KEY);

// ---------- Estado global ----------
const estado = {
  user: null,
  hoteles: [],        // [{id, nombre, color}]
  fichas: [],         // [{...}]
  registros: [],      // [{id, ficha_id, fecha, descripcion}]
  instancias: [],     // [{id, ficha_id, fecha, realizada}]
  mesActual: new Date(),
  fichaSeleccionada: null,
  filtroHotel: null,
  arrastrando: null,
};

// ---------- Utilidades ----------
const $ = (id) => document.getElementById(id);
const YYYYMMDD = (d) => {
  const y = d.getFullYear();
  const m = String(d.getMonth() + 1).padStart(2, '0');
  const dd = String(d.getDate()).padStart(2, '0');
  return `${y}-${m}-${dd}`;
};
const periodos = { manana: 'Mañana', tarde: 'Tarde', noche: 'Noche' };
const recurrenciaTxt = { puntual: 'Puntual (una vez)', diaria: 'Diaria', semanal: 'Semanal', mensual: 'Mensual' };

// ============================================================
// AUTH
// ============================================================
function mostrarLogin() { $('pantalla-login').classList.remove('hidden'); $('pantalla-app').classList.add('hidden'); }
function mostrarApp()   { $('pantalla-login').classList.add('hidden');    $('pantalla-app').classList.remove('hidden'); }
function mostrarError(el, msg) { el.textContent = msg; el.classList.remove('hidden'); }
function limpiarError(el) { el.classList.add('hidden'); el.textContent = ''; }

$('login-form').addEventListener('submit', async (e) => {
  e.preventDefault();
  limpiarError($('login-error'));
  $('login-btn').textContent = 'Ingresando...';
  const { error } = await sbClient.auth.signInWithPassword({
    email: $('login-email').value.trim(),
    password: $('login-pass').value,
  });
  $('login-btn').textContent = 'Ingresar';
  if (error) return mostrarError($('login-error'), error.message);
});

$('btn-logout').addEventListener('click', async () => { await sbClient.auth.signOut(); });

sbClient.auth.onAuthStateChange((event, session) => {
  estado.user = session ? session.user : null;
  if (estado.user) { cargarTodo(); mostrarApp(); }
  else { mostrarLogin(); }
});

// ============================================================
// CARGA DE DATOS
// ============================================================
async function cargarTodo() {
  estado.mesActual = new Date();
  await Promise.all([cargarHoteles(), cargarFichas(), cargarRegistros(), cargarInstancias()]);
  renderizarHoteles();
  renderizarTodo();
}

async function cargarHoteles() {
  const { data, error } = await sbClient.from('hoteles').select('*').order('nombre');
  if (error) { console.error(error); return; }
  estado.hoteles = data || [];
}
async function cargarFichas() {
  const { data, error } = await sbClient.from('fichas').select('*').order('orden');
  if (error) { console.error(error); return; }
  estado.fichas = data || [];
}
async function cargarRegistros() {
  const { data, error } = await sbClient.from('registros').select('*').order('fecha', { ascending: false });
  if (error) { console.error(error); return; }
  estado.registros = data || [];
}
async function cargarInstancias() {
  const { data, error } = await sbClient.from('instancias').select('*');
  if (error) { console.error(error); return; }
  estado.instancias = data || [];
}

function instanciaDe(fichaId, fechaStr) {
  return estado.instancias.find(i => i.ficha_id === fichaId && i.fecha === fechaStr) || null;
}
function fichaHechaEn(fichaId, fechaStr) {
  // Hecho = instancia realizada en esa fecha, o registro en esa fecha
  const inst = instanciaDe(fichaId, fechaStr);
  if (inst && inst.realizada) return true;
  return estado.registros.some(r => r.ficha_id === fichaId && r.fecha === fechaStr);
}

function hotelDe(id) { return estado.hoteles.find(h => h.id === id); }

// ============================================================
// RECURRENCIA: ¿ocurre la ficha en esta fecha?
// ============================================================
function fichaOcurreEn(ficha, date) {
  const rec = ficha.recurrencia || 'puntual';
  if (rec === 'diaria') return true;
  if (rec === 'semanal') {
    const dias = (ficha.dias_semana && ficha.dias_semana.length) ? ficha.dias_semana : [date.getDay()];
    return dias.includes(date.getDay());
  }
  if (rec === 'mensual') {
    const origen = ficha.fecha ? new Date(ficha.fecha) : date;
    return date.getDate() === (origen.getDate());
  }
  // puntual
  if (!ficha.fecha) return false;
  return YYYYMMDD(date) === ficha.fecha;
}

// ============================================================
// RENDER HOTELES
// ============================================================
function renderizarHoteles() {
  const filtro = $('hotel-filter');
  filtro.innerHTML = '';

  const chipTodos = document.createElement('span');
  chipTodos.className = 'hotel-chip' + (estado.filtroHotel === null ? ' active' : '');
  chipTodos.style.background = '#334155';
  chipTodos.style.color = '#e2e8f0';
  chipTodos.textContent = '🏨 Todos';
  chipTodos.addEventListener('click', () => { estado.filtroHotel = null; renderizarTodo(); renderizarHoteles(); });
  filtro.appendChild(chipTodos);

  estado.hoteles.forEach(h => {
    const chip = document.createElement('span');
    chip.className = 'hotel-chip' + (estado.filtroHotel === h.id ? ' active' : '');
    chip.style.background = h.color + '33';
    chip.style.color = h.color;
    chip.textContent = h.nombre;
    chip.addEventListener('click', () => { estado.filtroHotel = h.id; renderizarTodo(); renderizarHoteles(); });
    filtro.appendChild(chip);
  });

  const add = document.createElement('span');
  add.className = 'hotel-chip add';
  add.textContent = '+ Hotel';
  add.addEventListener('click', () => preguntarAgregarHotel());
  filtro.appendChild(add);

  const sel = $('f-hotel');
  sel.innerHTML = '';
  const optNull = document.createElement('option');
  optNull.value = '';
  optNull.textContent = '— Sin hotel —';
  sel.appendChild(optNull);
  estado.hoteles.forEach(h => {
    const o = document.createElement('option');
    o.value = h.id;
    o.textContent = h.nombre;
    sel.appendChild(o);
  });
}

async function preguntarAgregarHotel() {
  const nombre = prompt('Nombre del hotel:');
  if (!nombre || !nombre.trim()) return;
  const color = prompt('Color (hex), ej. #ef4444:', '#3b82f6');
  const { error } = await sbClient.from('hoteles').insert({ nombre: nombre.trim(), color: (color || '#3b82f6').trim() });
  if (error) { alert('Error: ' + error.message); return; }
  await cargarHoteles();
  renderizarHoteles();
  renderizarTodo();
}

// ============================================================
// RENDER CALENDARIO (tablero)
// ============================================================
function renderizarTodo() {
  renderizarMesTitulo();
  renderizarCalendario();
  renderizarBandeja();
}

function renderizarMesTitulo() {
  const meses = ['Enero','Febrero','Marzo','Abril','Mayo','Junio','Julio','Agosto','Septiembre','Octubre','Noviembre','Diciembre'];
  $('mes-titulo').textContent = `${meses[estado.mesActual.getMonth()]} ${estado.mesActual.getFullYear()}`;
}

// Devuelve las "piezas" (ficha + fecha concreta) de un mes, considerando recurrencia
function ocurrenciasDelMes(fichas, anio, mes) {
  const resultado = [];
  fichas.forEach(f => {
    if (f.fecha && !f.recurrencia) {
      // puntual con fecha -> usar su fecha si cae en el mes
      const d = new Date(f.fecha + 'T00:00:00');
      if (d.getFullYear() === anio && d.getMonth() === mes) {
        resultado.push({ ficha: f, fecha: f.fecha });
      }
      return;
    }
    // Recorrer todos los dias del mes y preguntar si ocurre
    const numDias = new Date(anio, mes + 1, 0).getDate();
    for (let dd = 1; dd <= numDias; dd++) {
      const d = new Date(anio, mes, dd);
      if (fichaOcurreEn(f, d)) {
        resultado.push({ ficha: f, fecha: YYYYMMDD(d) });
      }
    }
  });
  return resultado;
}

function renderizarCalendario() {
  const cal = $('calendario');
  cal.classList.add('tablero-fondo');
  cal.innerHTML = '';
  const diasSemana = ['Lun','Mar','Mié','Jue','Vie','Sáb','Dom'];

  diasSemana.forEach(d => {
    const h = document.createElement('div');
    h.className = 'cal-dia cabecera';
    h.textContent = d;
    cal.appendChild(h);
  });

  const anio = estado.mesActual.getFullYear();
  const mes = estado.mesActual.getMonth();
  const hoy = new Date();
  const hoyStr = YYYYMMDD(hoy);
  const todosFiltrados = filtrarFichas();
  const ocurrencias = ocurrenciasDelMes(todosFiltrados, anio, mes);

  // Indice por fecha: fechaStr -> [{ficha, fecha}]
  const porFecha = {};
  ocurrencias.forEach(o => {
    (porFecha[o.fecha] = porFecha[o.fecha] || []).push(o);
  });

  const primerDia = new Date(anio, mes, 1);
  let inicioObs = primerDia.getDay() === 0 ? -6 : 1 - primerDia.getDay();

  for (let i = 0; i < 42; i++) {
    const d = new Date(anio, mes, 1);
    d.setDate(d.getDate() + inicioObs + i);
    const fechaStr = YYYYMMDD(d);
    const celda = document.createElement('div');
    celda.className = 'cal-dia';
    celda.dataset.fecha = fechaStr;
    if (d.getMonth() !== mes) celda.classList.add('fuera');
    if (fechaStr === hoyStr) celda.classList.add('hoy');

    const esPasado = YYYYMMDD(d) < hoyStr && d.getMonth() === mes;

    // Numero + indicador
    const dayDatos = document.createElement('div');
    dayDatos.className = 'dia-num';
    const ocDelDia = porFecha[fechaStr] || [];
    const hayHecho = ocDelDia.some(o => fichaHechaEn(o.ficha.id, fechaStr));
    dayDatos.innerHTML = `<span>${d.getDate()}</span>${hayHecho ? '<span class="dia-indicador-registro"> ●</span>' : ''}`;
    celda.appendChild(dayDatos);

    ['manana', 'tarde', 'noche'].forEach(per => {
      const grupo = document.createElement('div');
      grupo.className = 'periodo-grupo';
      const label = document.createElement('div');
      label.className = 'periodo-label';
      label.textContent = periodos[per];
      grupo.appendChild(label);

      const celdas = document.createElement('div');
      celdas.className = 'periodo-celdas';
      celdas.dataset.fecha = fechaStr;
      celdas.dataset.periodo = per;

      const fichasPer = ocDelDia
        .filter(o => (o.ficha.periodo || 'manana') === per)
        .sort((a, b) => (a.ficha.orden || 0) - (b.ficha.orden || 0));

      fichasPer.forEach(o => celdas.appendChild(crearFichaDOM(o.ficha, o.fecha, esPasado)));

      grupo.appendChild(celdas);
      celda.appendChild(grupo);
    });

    cal.appendChild(celda);
  }
}

function filtrarFichas() {
  if (estado.filtroHotel === null) return estado.fichas;
  return estado.fichas.filter(f => f.hotel_id === estado.filtroHotel);
}

function renderizarBandeja() {
  const cont = $('bandeja-contenido');
  cont.innerHTML = '';
  // Bandeja: fichas puntuales sin fecha asignada
  const bandeja = filtrarFichas().filter(f => (!f.fecha && (f.recurrencia || 'puntual') === 'puntual') || (!f.fecha && !f.recurrencia));
  if (bandeja.length === 0) {
    cont.innerHTML = '<span style="color:#b9a889;font-size:13px;">Sin fichas pendientes de asignar.</span>';
    return;
  }
  bandeja.forEach(f => cont.appendChild(crearFichaDOM(f, null, false, true)));
}

// ============================================================
// CREAR FICHA DOM (post-it)
// ============================================================
function crearFichaDOM(ficha, fechaStr, esPasado, enBandeja = false) {
  const div = document.createElement('div');
  const hecho = fechaStr ? fichaHechaEn(ficha.id, fechaStr) : false;
  const vencida = esPasado && !hecho && fechaStr;

  div.className = 'ficha';
  if (hecho) div.classList.add('fija');
  if (vencida) div.classList.add('vencida');
  if (fechaStr) div.dataset.fechaFicha = fechaStr;

  // Los post-its hechos no se arrastran
  div.draggable = !hecho;

  const hotel = hotelDe(ficha.hotel_id);
  if (hotel) div.style.background = mezclarColor(hotel.color);

  const horas = ficha.hora ? `<div class="f-hora">🕒 ${escapar(ficha.hora)}</div>` : '';
  const marca = hecho ? '<span class="f-marca">✔ hecho</span>' : (vencida ? '<span class="f-marca">! vencida</span>' : '');
  div.innerHTML = `
    <div class="f-titulo">${ficha.emoji || '📌'} ${escapar(ficha.titulo)} ${bordeRecurrencia(ficha)}</div>
    ${horas}
    ${marca}
  `;

  div.addEventListener('mouseenter', (e) => mostrarVistaPrevia(e, ficha, fechaStr, hecho));
  div.addEventListener('mousemove', (e) => moverVistaPrevia(e));
  div.addEventListener('mouseleave', () => ocultarVistaPrevia());

  div.addEventListener('click', (e) => {
    e.stopPropagation();
    abrirDetalle(ficha.id, fechaStr);
  });

  if (div.draggable) configurarDrag(div, ficha, fechaStr);

  return div;
}

function bordeRecurrencia(ficha) {
  const r = ficha.recurrencia || 'puntual';
  if (r === 'diaria') return '🔁';
  if (r === 'semanal') return '↻';
  if (r === 'mensual') return '↻m';
  return '';
}

function mezclarColor(hex, alpha = 0.22) {
  const r = parseInt(hex.slice(1, 3), 16);
  const g = parseInt(hex.slice(3, 5), 16);
  const b = parseInt(hex.slice(5, 7), 16);
  // post-it claro para que la letra se lea oscura
  return `rgb(${Math.round(r + (255 - r) * alpha)}, ${Math.round(g + (255 - g) * alpha)}, ${Math.round(b + (255 - b) * alpha)})`;
}

function configurarDrag(div, ficha, fechaStr) {
  div.addEventListener('dragstart', (e) => {
    estado.arrastrando = { ficha, fecha: fechaStr };
    div.classList.add('dragging');
    e.dataTransfer.effectAllowed = 'move';
    try { e.dataTransfer.setData('text/plain', ficha.id); } catch (_) {}
  });
  div.addEventListener('dragend', () => {
    div.classList.remove('dragging');
    estado.arrastrando = null;
    document.querySelectorAll('.cal-dia.destino').forEach(c => c.classList.remove('destino'));
  });
}

// ---------- Drop ----------
document.addEventListener('dragover', (e) => {
  const celda = e.target.closest('.periodo-celdas');
  if (!celda || !estado.arrastrando) return;
  e.preventDefault();
  e.dataTransfer.dropEffect = 'move';
  const dia = celda.closest('.cal-dia');
  if (dia) dia.classList.add('destino');
});
document.addEventListener('dragleave', (e) => {
  if (e.target.closest('.cal-dia')) return;
  document.querySelectorAll('.cal-dia.destino').forEach(c => c.classList.remove('destino'));
});
document.addEventListener('drop', async (e) => {
  const celda = e.target.closest('.periodo-celdas');
  if (!celda || !estado.arrastrando) return;
  e.preventDefault();
  const { ficha, fecha } = estado.arrastrando;
  const nuevaFecha = celda.dataset.fecha;
  const nuevoPeriodo = celda.dataset.periodo;

  // Si es una ocurrencia recurrente ya hecha -> no se mueve
  if (fecha && fichaHechaEn(ficha.id, fecha)) return;

  if (fecha) {
    // Ocurrencia recurrente: la movemos a la nueva fecha creando un "hueco" no realizado
    // en la original y agregando esta ficha como puntual en la nueva? No.
    // Para recurrencias, mover la ocurrencia = actualizar fecha base de la serie.
    const esRecurrente = (ficha.recurrencia || 'puntual') !== 'puntual';
    if (!esRecurrente) {
      // Puntual: simplemente mover su fecha
      await sbClient.from('fichas').update({ fecha: nuevaFecha, periodo: nuevoPeriodo }).eq('id', ficha.id);
    } else {
      // Recurrente: creamos una instancia "realizada=false" en la fecha origen para
      // suprimirla, y una copia puntual en el destino (ocurrencia movida).
      await sbClient.from('instancias').insert({
        ficha_id: ficha.id, fecha, realizada: false,
        user_id: estado.user.id,
      }).then(() => {});
      await sbClient.from('fichas').insert({
        user_id: estado.user.id,
        hotel_id: ficha.hotel_id,
        emoji: ficha.emoji, titulo: ficha.titulo, descripcion: ficha.descripcion,
        periodo: nuevoPeriodo, fecha: nuevaFecha,
        hora: ficha.hora, responsable: ficha.responsable,
        recurrencia: 'puntual', fija: false, orden: ficha.orden + 1,
      });
    }
  } else {
    // Ficha de bandeja -> asignar fecha
    await sbClient.from('fichas').update({ fecha: nuevaFecha, periodo: nuevoPeriodo }).eq('id', ficha.id);
  }

  document.querySelectorAll('.cal-dia.destino').forEach(c => c.classList.remove('destino'));
  estado.arrastrando = null;
  await Promise.all([cargarFichas(), cargarInstancias()]);
  renderizarTodo();
});

// ============================================================
// VISTA PREVIA
// ============================================================
function mostrarVistaPrevia(e, ficha, fechaStr, hecho) {
  const vp = $('vista-previa');
  const hotel = hotelDe(ficha.hotel_id);
  const recurrente = (ficha.recurrencia || 'puntual') !== 'puntual';
  vp.innerHTML = `
    <div class="vp-emoji">${ficha.emoji || '📌'}</div>
    <div class="vp-titulo">${escapar(ficha.titulo)}</div>
    ${fechaStr ? `<div class="vp-fecha">📅 ${fechaStr}</div>` : ''}
    ${hotel ? `<span class="vp-hotel" style="background:${hotel.color}">${escapar(hotel.nombre)}</span>` : ''}
    ${ficha.hora ? `<div class="vp-desc">🕒 ${escapar(ficha.hora)}</div>` : ''}
    ${ficha.responsable ? `<div class="vp-desc">👤 ${escapar(ficha.responsable)}</div>` : ''}
    ${recurrente ? `<div class="vp-fija">🔁 ${recurrenciaTxt[ficha.recurrencia] || 'Recurrente'}</div>` : ''}
    ${ficha.descripcion ? `<div class="vp-desc">${escapar(ficha.descripcion)}</div>` : ''}
    ${hecho ? `<div class="vp-fija">✔ Hecho</div>` : ''}
  `;
  vp.classList.remove('hidden');
  moverVistaPrevia(e);
}
function moverVistaPrevia(e) {
  const vp = $('vista-previa');
  vp.style.left = Math.min(e.clientX + 14, window.innerWidth - 280) + 'px';
  vp.style.top = (e.clientY + 14) + 'px';
}
function ocultarVistaPrevia() { $('vista-previa').classList.add('hidden'); }

// ============================================================
// MODAL NUEVA FICHA
// ============================================================
let editandoFichaId = null;

$('btn-nueva-ficha').addEventListener('click', () => abrirModalNueva());
$('f-cancelar').addEventListener('click', () => cerrarModalFicha());

function abrirModalNueva(fechaSugerida, periodoSugerido, fichaExistente) {
  editandoFichaId = fichaExistente ? fichaExistente.id : null;
  $('modal-ficha-titulo').textContent = fichaExistente ? 'Editar ficha' : 'Nueva ficha';
  $('f-emoji').value = fichaExistente ? (fichaExistente.emoji || '') : '';
  $('f-titulo').value = fichaExistente ? fichaExistente.titulo : '';
  $('f-hotel').value = fichaExistente ? (fichaExistente.hotel_id || '') : (estado.filtroHotel || '');
  $('f-periodo').value = fichaExistente ? fichaExistente.periodo : (periodoSugerido || 'manana');
  $('f-fecha').value = fichaExistente ? (fichaExistente.fecha || '') : (fechaSugerida || '');
  $('f-recurrencia').value = fichaExistente ? (fichaExistente.recurrencia || 'puntual') : 'puntual';
  $('f-hora').value = fichaExistente ? (fichaExistente.hora || '') : '';
  $('f-responsable').value = fichaExistente ? (fichaExistente.responsable || '') : '';
  $('f-descripcion').value = fichaExistente ? (fichaExistente.descripcion || '') : '';
  $('modal-ficha').classList.remove('hidden');
}

function cerrarModalFicha() {
  $('modal-ficha').classList.add('hidden');
  editandoFichaId = null;
}

$('form-ficha').addEventListener('submit', async (e) => {
  e.preventDefault();
  const recurrencia = $('f-recurrencia').value;
  let dias_semana = null;
  if (recurrencia === 'semanal' && $('f-fecha').value) {
    dias_semana = [new Date($('f-fecha').value + 'T00:00:00').getDay()];
  }
  const payload = {
    emoji: $('f-emoji').value.trim() || null,
    titulo: $('f-titulo').value.trim(),
    hotel_id: $('f-hotel').value || null,
    periodo: $('f-periodo').value,
    fecha: $('f-fecha').value || null,
    recurrencia,
    dias_semana,
    hora: $('f-hora').value || null,
    responsable: $('f-responsable').value.trim() || null,
    descripcion: $('f-descripcion').value.trim(),
  };
  if (!payload.titulo) return;

  if (editandoFichaId) {
    const { error } = await sbClient.from('fichas').update(payload).eq('id', editandoFichaId);
    if (error) { alert('Error: ' + error.message); return; }
  } else {
    const { error } = await sbClient.from('fichas').insert(payload);
    if (error) { alert('Error: ' + error.message); return; }
  }
  cerrarModalFicha();
  await cargarFichas();
  renderizarTodo();
});

// ============================================================
// DETALLE FICHA + REGISTRO
// ============================================================
function abrirDetalle(fichaId, fechaCtx) {
  const f = estado.fichas.find(x => x.id === fichaId);
  if (!f) return;
  estado.fichaSeleccionada = f;
  estado.fechaCtx = fechaCtx || null;

  $('d-emoji').textContent = f.emoji || '📌';
  $('d-titulo').textContent = f.titulo;
  $('d-periodo').textContent = '🕒 ' + periodos[f.periodo];
  $('d-fecha').textContent = fechaCtx ? '📅 ' + fechaCtx : (f.fecha ? '📅 ' + f.fecha : '📋 En bandeja');
  $('d-descripcion').textContent = f.descripcion || 'Sin descripción.';

  // Meta chips
  const meta = $('d-meta');
  meta.innerHTML = '';
  if (f.hora) meta.innerHTML += `<span class="meta-chip">🕒 ${escapar(f.hora)}</span>`;
  if (f.responsable) meta.innerHTML += `<span class="meta-chip">👤 ${escapar(f.responsable)}</span>`;
  if ((f.recurrencia || 'puntual') !== 'puntual') {
    meta.innerHTML += `<span class="meta-chip">🔁 ${recurrenciaTxt[f.recurrencia] || 'Recurrente'}</span>`;
  }

  const hotel = hotelDe(f.hotel_id);
  const badge = $('d-hotel-badge');
  if (hotel) { badge.style.background = hotel.color; badge.textContent = '🏨 ' + hotel.nombre; badge.classList.remove('hidden'); }
  else { badge.classList.add('hidden'); }

  const recurrente = (f.recurrencia || 'puntual') !== 'puntual';
  $('d-recurrencia-aviso').classList.toggle('hidden', !recurrente);
  $('d-recurrencia-txt').textContent = recurrenciaTxt[f.recurrencia] || 'Recurrente';

  // Para ocurrencias recurrentes: aviso fija segun esta fecha
  const hecha = fechaCtx ? fichaHechaEn(f.id, fechaCtx) : fichaHechaEn(f.id, f.fecha || '');
  $('d-fija-aviso').textContent = hecha
    ? '✔ Este posit ya fue marcado como hecho.'
    : '🔒 Cuando registres el trabajo, este posit quedará fijo (no se moverá).';
  $('d-fija-aviso').classList.toggle('hidden', false);

  // Registros
  const registros = estado.registros.filter(r => r.ficha_id === f.id);
  const contReg = $('d-registros');
  contReg.innerHTML = '';
  if (registros.length === 0) {
    contReg.innerHTML = '<div style="color:var(--text-dim);font-size:13px;">Sin registros aún.</div>';
  } else {
    registros.forEach(r => {
      const item = document.createElement('div');
      item.className = 'registro-item';
      item.innerHTML = `<div class="r-fecha">📅 ${r.fecha}</div><div class="r-text">${escapar(r.descripcion || '(sin detalle)')}</div>`;
      contReg.appendChild(item);
    });
  }

  // Instancias / ocurrencias (solo recurrentes) - listamos fechas del mes
  if (recurrente) {
    const $bloque = $('d-instancias-bloque');
    $bloque.classList.remove('hidden');
    const anio = estado.mesActual.getFullYear();
    const mes = estado.mesActual.getMonth();
    const numDias = new Date(anio, mes + 1, 0).getDate();
    const cont = $('d-instancias');
    cont.innerHTML = '';
    for (let dd = 1; dd <= numDias; dd++) {
      const d = new Date(anio, mes, dd);
      if (!fichaOcurreEn(f, d)) continue;
      const fs = YYYYMMDD(d);
      const hechaI = fichaHechaEn(f.id, fs);
      const el = document.createElement('span');
      el.className = 'instancia ' + (hechaI ? 'hecha' : 'porhacer');
      el.textContent = `${dd} ${hechaI ? '✔' : '·'}`;
      el.title = fs;
      el.addEventListener('click', () => {
        const f2 = estado.fichas.find(x => x.id === f.id);
        abrirDetalle(f2.id, fs);
      });
      cont.appendChild(el);
    }
  } else {
    $('d-instancias-bloque').classList.add('hidden');
  }

  $('r-descripcion').value = '';
  $('modal-ficha-detalle').classList.remove('hidden');
}

$('d-cerrar').addEventListener('click', () => $('modal-ficha-detalle').classList.add('hidden'));

document.querySelectorAll('.modal-overlay').forEach(m => {
  m.addEventListener('click', (e) => { if (e.target === m) m.classList.add('hidden'); });
});

$('d-editar').addEventListener('click', () => {
  const f = estado.fichaSeleccionada;
  if (!f) return;
  $('modal-ficha-detalle').classList.add('hidden');
  abrirModalNueva(null, null, f);
});

$('d-eliminar').addEventListener('click', async () => {
  const f = estado.fichaSeleccionada;
  if (!f) return;
  if (!confirm(`¿Eliminar la ficha "${f.titulo}"?`)) return;
  const { error } = await sbClient.from('fichas').delete().eq('id', f.id);
  if (error) { alert('Error: ' + error.message); return; }
  $('modal-ficha-detalle').classList.add('hidden');
  await Promise.all([cargarFichas(), cargarRegistros(), cargarInstancias()]);
  renderizarTodo();
});

// Registrar trabajo hecho -> crea registro + instancia (bloquea el posit)
$('form-registro').addEventListener('submit', async (e) => {
  e.preventDefault();
  const f = estado.fichaSeleccionada;
  if (!f) return;
  const fecha = estado.fechaCtx || f.fecha || YYYYMMDD(new Date());
  const desc = $('r-descripcion').value.trim();

  await Promise.all([
    sbClient.from('registros').insert({ ficha_id: f.id, fecha, descripcion: desc }),
    sbClient.from('instancias').upsert({ ficha_id: f.id, fecha, realizada: true }, { onConflict: 'ficha_id,fecha' }),
  ]);
  await sbClient.from('fichas').update({ fija: true }).eq('id', f.id);

  $('r-descripcion').value = '';
  await Promise.all([cargarFichas(), cargarRegistros(), cargarInstancias()]);
  abrirDetalle(f.id, fecha);
  renderizarTodo();
});

// ============================================================
// NAVEGACION DE MES
// ============================================================
$('btn-mes-anterior').addEventListener('click', () => { estado.mesActual.setMonth(estado.mesActual.getMonth() - 1); renderizarTodo(); });
$('btn-mes-siguiente').addEventListener('click', () => { estado.mesActual.setMonth(estado.mesActual.getMonth() + 1); renderizarTodo(); });
$('btn-hoy').addEventListener('click', () => { estado.mesActual = new Date(); renderizarTodo(); });

// ============================================================
// Helpers
// ============================================================
function escapar(str) {
  const div = document.createElement('div');
  div.textContent = str == null ? '' : String(str);
  return div.innerHTML;
}

// Inicio
if (SUPABASE_URL && SUPABASE_URL !== 'SIN_CONFIGURAR') {
  sbClient.auth.getSession().then(({ data }) => {
    if (data.session) {
      estado.user = data.session.user;
      cargarTodo();
      mostrarApp();
    } else {
      mostrarLogin();
    }
  });
}

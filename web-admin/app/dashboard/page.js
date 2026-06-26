'use client';

import { useState, useEffect } from 'react';
import { useRouter } from 'next/navigation';
import '../globals.css';

export default function DashboardPage() {
  const [requests, setRequests] = useState([]);
  const [filter, setFilter] = useState('todas');
  const [loading, setLoading] = useState(true);
  const [reloading, setReloading] = useState(false);
  const [adminName, setAdminName] = useState('');
  
  // Modal state
  const [modalOpen, setModalOpen] = useState(false);
  const [selectedReq, setSelectedReq] = useState(null);
  const [decisionType, setDecisionType] = useState('aprobado'); // 'aprobado' or 'rechazado'
  const [montoAprobado, setMontoAprobado] = useState('');
  const [motivo, setMotivo] = useState('');

  const router = useRouter();

  const fetchRequests = async (currentFilter = filter, isManual = false) => {
    if (isManual) setReloading(true);
    else setLoading(true);
    const token = localStorage.getItem('admin_jwt');
    if (!token) {
      router.push('/');
      return;
    }

    try {
      const url = new URL('http://127.0.0.1:8003/admin/solicitudes');
      if (currentFilter !== 'todas') {
        url.searchParams.append('estado', currentFilter);
      }

      const res = await fetch(url, {
        headers: { 'Authorization': `Bearer ${token}` }
      });

      if (!res.ok) throw new Error('Failed to fetch');
      const data = await res.json();
      setRequests(data);
    } catch (err) {
      console.error(err);
    } finally {
      setLoading(false);
      setReloading(false);
    }
  };

  useEffect(() => {
    setAdminName(localStorage.getItem('admin_name') || 'Admin');
    fetchRequests();
  }, []);

  const handleFilterChange = (newFilter) => {
    setFilter(newFilter);
    fetchRequests(newFilter);
  };

  const handleLogout = () => {
    localStorage.removeItem('admin_jwt');
    localStorage.removeItem('admin_name');
    router.push('/');
  };

  const openDecisionModal = (req, type) => {
    setSelectedReq(req);
    setDecisionType(type);
    setMontoAprobado(type === 'aprobado' ? req.monto_solicitado.toString() : '');
    setMotivo('');
    setModalOpen(true);
  };

  const submitDecision = async () => {
    const token = localStorage.getItem('admin_jwt');
    try {
      const res = await fetch(`http://127.0.0.1:8003/admin/solicitudes/${selectedReq.id}/decision`, {
        method: 'POST',
        headers: {
          'Authorization': `Bearer ${token}`,
          'Content-Type': 'application/json'
        },
        body: JSON.stringify({
          decision: decisionType,
          monto_aprobado: decisionType === 'aprobado' ? parseFloat(montoAprobado) : null,
          motivo: motivo.trim()
        })
      });

      if (res.ok) {
        setModalOpen(false);
        fetchRequests();
      } else {
        const errData = await res.json();
        alert('Error: ' + errData.detail);
      }
    } catch (err) {
      alert('Error de conexión');
    }
  };

  const filters = ['todas', 'borrador', 'recibido_comite', 'desembolsado', 'rechazado'];

  return (
    <div className="dashboard-layout">
      <header className="topbar">
        <div className="topbar-logo">Interbank UC</div>
        <div className="user-profile">
          <span>{adminName}</span>
          <div className="user-avatar">{adminName.charAt(0)}</div>
          <button className="btn-sm" style={{marginLeft: 16}} onClick={handleLogout}>Salir</button>
        </div>
      </header>

      <main className="dashboard-content">
        <div className="page-header">
          <div style={{ display: 'flex', alignItems: 'center', gap: 12 }}>
            <h1 className="page-title">Solicitudes de Crédito</h1>
            <button
              onClick={() => fetchRequests(filter, true)}
              title="Actualizar"
              style={{
                background: 'none',
                border: '1.5px solid #dde6ee',
                borderRadius: 8,
                padding: '6px 10px',
                cursor: reloading ? 'not-allowed' : 'pointer',
                display: 'flex',
                alignItems: 'center',
                gap: 6,
                color: '#1a3c5e',
                fontWeight: 600,
                fontSize: 13,
                transition: 'all 0.2s',
              }}
              disabled={reloading}
            >
              <svg
                width="15" height="15" viewBox="0 0 24 24" fill="none"
                stroke="currentColor" strokeWidth="2.2" strokeLinecap="round" strokeLinejoin="round"
                style={{ animation: reloading ? 'spin 0.7s linear infinite' : 'none' }}
              >
                <polyline points="23 4 23 10 17 10"/>
                <polyline points="1 20 1 14 7 14"/>
                <path d="M3.51 9a9 9 0 0 1 14.85-3.36L23 10M1 14l4.64 4.36A9 9 0 0 0 20.49 15"/>
              </svg>
              {reloading ? 'Actualizando...' : 'Actualizar'}
            </button>
          </div>
          <div className="filters">
            {filters.map(f => (
              <button 
                key={f}
                className={`filter-chip ${filter === f ? 'active' : ''}`}
                onClick={() => handleFilterChange(f)}
              >
                {f.replace('_', ' ').toUpperCase()}
              </button>
            ))}
          </div>
        </div>

        {loading ? (
          <div className="empty-state">Cargando solicitudes...</div>
        ) : requests.length === 0 ? (
          <div className="empty-state">
            <div className="empty-icon">📭</div>
            <h2>No hay solicitudes</h2>
            <p>No se encontraron solicitudes para el filtro seleccionado.</p>
          </div>
        ) : (
          <div className="requests-grid">
            {requests.map(req => {
              const canDecide = ['recibido_comite', 'enviado', 'en_evaluacion'].includes(req.estado);
              return (
                <div key={req.id} className={`request-card ${req.estado}`}>
                  <div className="req-main">
                    <div className="req-header">
                      <span className="req-id">{req.numero_expediente}</span>
                      <span className={`req-status ${req.estado}`}>{req.estado.replace('_', ' ')}</span>
                    </div>
                    <div className="req-client">{req.cliente_nombre}</div>
                    <div className="req-details">
                      <div><strong style={{color:'var(--text-main)'}}>Vendedor:</strong> {req.asesor_nombre}</div>
                      <div><strong style={{color:'var(--text-main)'}}>DNI:</strong> {req.numero_documento}</div>
                      <div><strong style={{color:'var(--text-main)'}}>Destino:</strong> {req.destino_credito}</div>
                      <div><strong style={{color:'var(--text-main)'}}>Ingresos:</strong> S/ {req.ingresos_estimados || 0}</div>
                    </div>
                  </div>
                  
                  <div className="req-amount-block">
                    <div className="req-amount">
                      S/ {(req.monto_solicitado || 0).toFixed(2)}
                    </div>
                    {canDecide && (
                      <div className="req-actions">
                        <button className="btn-sm btn-reject" onClick={() => openDecisionModal(req, 'rechazado')}>
                          Rechazar
                        </button>
                        <button className="btn-sm btn-approve" onClick={() => openDecisionModal(req, 'aprobado')}>
                          Aprobar
                        </button>
                      </div>
                    )}
                  </div>
                </div>
              );
            })}
          </div>
        )}
      </main>

      {modalOpen && selectedReq && (
        <div className="modal-overlay">
          <div className="modal-content">
            <div className="modal-header">
              <h2 className="modal-title">
                {decisionType === 'aprobado' ? 'Aprobar Solicitud' : 'Rechazar Solicitud'}
              </h2>
              <p style={{color: 'var(--text-muted)', marginTop: 8}}>
                Expediente: {selectedReq.numero_expediente}
              </p>
            </div>

            {decisionType === 'aprobado' && (
              <div className="form-group">
                <label className="form-label">Monto Aprobado (S/)</label>
                <input 
                  type="number" 
                  className="form-input" 
                  value={montoAprobado}
                  onChange={(e) => setMontoAprobado(e.target.value)}
                />
              </div>
            )}

            <div className="form-group">
              <label className="form-label">
                {decisionType === 'aprobado' ? 'Observación (Opcional)' : 'Motivo obligatorio'}
              </label>
              <textarea 
                className="form-input" 
                rows="3"
                value={motivo}
                onChange={(e) => setMotivo(e.target.value)}
                placeholder={decisionType === 'rechazado' ? 'Explique el motivo del rechazo...' : ''}
              ></textarea>
            </div>

            <div className="modal-actions">
              <button className="btn btn-ghost" style={{width: 'auto'}} onClick={() => setModalOpen(false)}>
                Cancelar
              </button>
              <button 
                className={`btn ${decisionType === 'aprobado' ? 'btn-primary' : ''}`}
                style={{width: 'auto', background: decisionType === 'rechazado' ? 'var(--accent)' : ''}}
                onClick={submitDecision}
              >
                Confirmar
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}

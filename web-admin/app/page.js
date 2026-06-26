'use client';

import { useState } from 'react';
import { useRouter } from 'next/navigation';
import './globals.css';

export default function LoginPage() {
  const [codigo, setCodigo] = useState('0001');
  const [password, setPassword] = useState('1234');
  const [error, setError] = useState('');
  const [loading, setLoading] = useState(false);
  const router = useRouter();

  const handleLogin = async (e) => {
    e.preventDefault();
    setLoading(true);
    setError('');

    try {
      const res = await fetch('http://127.0.0.1:8003/auth/login', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ codigo_empleado: codigo, password }),
      });

      if (!res.ok) {
        setError('Credenciales inválidas');
        setLoading(false);
        return;
      }

      const data = await res.json();
      const profile = data.asesor.perfil;
      
      if (!['supervisor', 'administrador', 'super_operador'].includes(profile)) {
        setError('Se requiere perfil supervisor/administrador');
        setLoading(false);
        return;
      }

      localStorage.setItem('admin_jwt', data.access_token);
      localStorage.setItem('admin_name', `${data.asesor.nombres} ${data.asesor.apellidos}`);
      
      router.push('/dashboard');
    } catch (err) {
      setError('Error de conexión al servidor');
      setLoading(false);
    }
  };

  return (
    <div className="auth-container">
      <div className="auth-card">
        <div className="auth-header">
          <h1>Comité de Créditos</h1>
          <p>Interbank UC - acceso supervisor</p>
        </div>
        
        <form onSubmit={handleLogin}>
          <div className="form-group">
            <label className="form-label">Código de empleado</label>
            <input 
              type="text" 
              className="form-input" 
              value={codigo}
              onChange={(e) => setCodigo(e.target.value)}
              required 
            />
          </div>
          
          <div className="form-group">
            <label className="form-label">Contraseña</label>
            <input 
              type="password" 
              className="form-input" 
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              required 
            />
          </div>

          {error && <div className="form-error" style={{marginBottom: '16px'}}>{error}</div>}
          
          <button type="submit" className="btn btn-primary" disabled={loading}>
            {loading ? 'Ingresando...' : 'Ingresar'}
          </button>
        </form>
      </div>
    </div>
  );
}

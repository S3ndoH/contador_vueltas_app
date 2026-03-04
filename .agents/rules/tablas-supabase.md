---
trigger: always_on
---

-- 1. Habilitar extensiones necesarias
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- 2. Tabla de Entrenamientos (Sesiones)
-- Almacena la información general de cada sesión de práctica
CREATE TABLE trainings (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    started_at TIMESTAMPTZ DEFAULT NOW(),
    track_length_meters INTEGER DEFAULT 200, -- Longitud de la pista (200m por defecto)
    description TEXT,
    
    -- Restricción de integridad para el usuario
    CONSTRAINT fk_user FOREIGN KEY (user_id) REFERENCES auth.users(id)
);

-- 3. Tabla de Vueltas (Laps)
-- Almacena cada vuelta individual (Nx) asociada a un entrenamiento
CREATE TABLE laps (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    training_id UUID NOT NULL REFERENCES trainings(id) ON DELETE CASCADE,
    lap_number INTEGER NOT NULL, -- Número de vuelta Nx
    average_speed NUMERIC(5, 2) NOT NULL, -- Velocidad promedio en la vuelta
    duration_seconds NUMERIC(8, 3) NOT NULL, -- Tiempo en segundos de la vuelta
    created_at TIMESTAMPTZ DEFAULT NOW(),

    -- Evita que existan números de vuelta duplicados en la misma sesión
    UNIQUE (training_id, lap_number)
);

-- 4. Seguridad de Nivel de Fila (RLS)
-- Crucial para proteger la privacidad de los datos de cada patinador
ALTER TABLE trainings ENABLE ROW LEVEL SECURITY;
ALTER TABLE laps ENABLE ROW LEVEL SECURITY;

-- Políticas para la tabla 'trainings'
CREATE POLICY "Usuarios pueden gestionar sus propios entrenamientos"
ON trainings FOR ALL 
USING (auth.uid() = user_id);

-- Políticas para la tabla 'laps' (basadas en la propiedad del entrenamiento)
CREATE POLICY "Usuarios pueden gestionar sus propias vueltas"
ON laps FOR ALL 
USING (
    EXISTS (
        SELECT 1 FROM trainings 
        WHERE trainings.id = laps.training_id 
        AND trainings.user_id = auth.uid()
    )
);

-- 5. Vista de Resumen de Entrenamientos
-- Facilita la carga del historial en Flutter con cálculos ya procesados
CREATE OR REPLACE VIEW training_summaries AS
SELECT 
    t.id AS training_id,
    t.user_id,
    t.started_at,
    t.description,
    COUNT(l.id) AS total_laps,
    ROUND(AVG(l.average_speed), 2) AS session_avg_speed,
    MAX(l.average_speed) AS max_speed,
    SUM(l.duration_seconds) AS total_duration_seconds
FROM trainings t
LEFT JOIN laps l ON t.id = l.training_id
GROUP BY t.id, t.user_id, t.started_at, t.description;

-- 6. Función RPC para estadísticas detalladas
-- Se llama desde Flutter usando: supabase.rpc('get_training_stats', params: {'t_id': '...'})
CREATE OR REPLACE FUNCTION get_training_stats(t_id UUID)
RETURNS TABLE (
    total_laps BIGINT,
    avg_speed NUMERIC,
    max_speed NUMERIC,
    total_distance_meters NUMERIC
) 
LANGUAGE plpgsql
SECURITY DEFINER -- Permite ejecutar el cálculo ignorando temporalmente RLS para esta consulta
AS $$
BEGIN
    RETURN QUERY
    SELECT 
        COUNT(*),
        ROUND(AVG(average_speed), 2),
        MAX(average_speed),
        (COUNT(*) * (SELECT track_length_meters FROM trainings WHERE id = t_id))::NUMERIC
    FROM laps
    WHERE training_id = t_id;
END;
$$;

-- 7. Índices para optimizar el rendimiento de las consultas
CREATE INDEX idx_trainings_user_id ON trainings(user_id);
CREATE INDEX idx_laps_training_id ON laps(training_id);
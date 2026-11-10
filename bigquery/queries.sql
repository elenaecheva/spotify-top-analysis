
-- Básico: top 10
SELECT puesto, cancion, artista, album
FROM `groovy-karma-514308-v4.music.lista_top_50`
WHERE puesto <=10
ORDER BY puesto;

-- Agregación: artistas más presentes y su mejor puesto
SELECT artista,
      COUNT(*) AS canciones,
      MIN(puesto) AS mejor_puesto,
      ROUND(AVG(puesto),1) AS puesto_medio
FROM `groovy-karma-514308-v4.music.lista_top_50`
GROUP BY artista
HAVING COUNT(*) >1
ORDER BY canciones DESC, mejor_puesto;

-- CASE: reparto por tramos por ranking
SELECT
  CASE
    WHEN puesto <= 10 THEN 'Top 10'
    WHEN puesto <= 25 THEN '11-25'
    ELSE '26-50'
  END AS tramo,
  COUNT(DISTINCT artista) AS artistas_distintos,
  COUNT(*) AS canciones
FROM `groovy-karma-514308-v4.music.lista_top_50`
GROUP BY tramo
ORDER BY MIN(puesto);

-- La canción mejor posiciona de cada artista
SELECT puesto, cancion, artista
FROM (
  SELECT *, 
        ROW_NUMBER() OVER (PARTITION BY artista ORDER BY puesto) AS rn
  FROM `groovy-karma-514308-v4.music.lista_top_50`
)
WHERE rn = 1
ORDER BY puesto;

-- JOIN con resumen_visual
WITH conteo_top50 AS (
  SELECT album, artista, COUNT(*) AS canciones_top50
  FROM `groovy-karma-514308-v4.music.lista_top_50`
  GROUP BY album, artista
)
SELECT
  COALESCE(t.album, r.album) AS album,
  COALESCE(t.artista, r.artista) AS artista,
  t.canciones_top50,
  r.total AS total_resumen,
  CASE
    WHEN t.canciones_top50 = r.total THEN 'OK'
    WHEN r.total IS NULL THEN 'Falta en resumen'
    WHEN t.canciones_top50 IS NULL THEN 'Falta en top 50'
    ELSE 'No cuadra'
  END AS validacion
FROM conteo_top50 t
FULL OUTER JOIN `groovy-karma-514308-v4.music.resumen_visual` r
  ON t.album = r.album AND t.artista = r.artista
ORDER BY validacion DESC, album;


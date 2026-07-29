# =============================================================
# Spotify Top Analysis
# Obtiene tus artistas/canciones más escuchados vía Spotify Web API
# (OAuth Authorization Code Flow con httr2)
# =============================================================

library(httr2)
library(dplyr)
library(ggplot2)

# -------------------------------------------------------------
# 1. Autenticación
# -------------------------------------------------------------
# Credenciales cargadas desde .Renviron (NUNCA se escriben aquí).
# Crea un archivo .Renviron en la raíz del proyecto con:
#   SPOTIFY_CLIENT_ID=tu_id
#   SPOTIFY_CLIENT_SECRET=tu_secret
# Y añade ".Renviron" a tu .gitignore.

oauth_client <- oauth_client(
  id = Sys.getenv("SPOTIFY_CLIENT_ID"),
  secret = Sys.getenv("SPOTIFY_CLIENT_SECRET"),
  token_url = "https://accounts.spotify.com/api/token"
)

token <- oauth_flow_auth_code(
  client = oauth_client,
  auth_url = "https://accounts.spotify.com/authorize",
  scope = "playlist-read-private user-top-read",
  redirect_uri = "http://127.0.0.1:1410/"
)

# -------------------------------------------------------------
# 2. Función reutilizable para pedir "top artists" o "top tracks"
# -------------------------------------------------------------
# tipo: "artists" o "tracks"
# time_range: "short_term" (~4 semanas), "medium_term" (~6 meses), "long_term" (varios años)
get_top <- function(token, tipo = "tracks", limit = 10, time_range = "long_term") {
  endpoint <- paste0("https://api.spotify.com/v1/me/top/", tipo)

  request(endpoint) %>%
    req_auth_bearer_token(token$access_token) %>%
    req_url_query(limit = limit, time_range = time_range) %>%
    req_perform() %>%
    resp_body_json()
}

# -------------------------------------------------------------
# 3. Ejemplos de uso
# -------------------------------------------------------------

# Top 10 artistas de siempre
top_artists <- get_top(token, tipo = "artists", limit = 10, time_range = "long_term")
sapply(top_artists$items, function(x) x$name)

# Top 20 artistas de siempre
top_artists_20 <- get_top(token, tipo = "artists", limit = 20, time_range = "long_term")

# Top 10 canciones de siempre, formateadas como "Canción - Artista"
top_tracks <- get_top(token, tipo = "tracks", limit = 10, time_range = "long_term")

top_10_lista <- sapply(top_tracks$items, function(track) {
  artistas <- paste(sapply(track$artists, function(a) a$name), collapse = ", ")
  paste0(track$name, " - ", artistas)
})
print(top_10_lista)

# -------------------------------------------------------------
# 4. Análisis: álbumes más presentes en el Top 50
# -------------------------------------------------------------

top_tracks_50 <- get_top(token, tipo = "tracks", limit = 50, time_range = "long_term")

albumes_top <- lapply(top_tracks_50$items, function(x) {
  data.frame(
    cancion = x$name,
    album = x$album$name,
    artista = x$album$artists[[1]]$name,
    stringsAsFactors = FALSE
  )
}) %>% bind_rows()

resumen_visual <- albumes_top %>%
  group_by(album, artista) %>%
  summarise(
    total = n(),
    que_canciones = paste(cancion, collapse = " | "),
    .groups = "drop"
  ) %>%
  arrange(desc(total))

print(resumen_visual)

# -------------------------------------------------------------
# 5. Visualización: top 10 álbumes en el Top 50
# -------------------------------------------------------------

resumen_visual_top10 <- resumen_visual[1:10, ]

# Ordenamos el factor 'artista' para que la leyenda siga el orden de las barras
resumen_visual_top10$artista <- factor(
  resumen_visual_top10$artista,
  levels = unique(resumen_visual_top10$artista[order(resumen_visual_top10$total, decreasing = TRUE)])
)

ggplot(resumen_visual_top10, aes(x = reorder(album, total), y = total, fill = artista)) +
  geom_col(width = 0.8) +
  geom_text(aes(label = total), hjust = -0.3, size = 4, fontface = "bold") +
  coord_flip() +
  scale_fill_brewer(palette = "Set3") +
  labs(
    title = "Dominio de álbumes en mi Top 50",
    subtitle = "Basado en el número de canciones por disco",
    x = NULL,
    y = "Canciones en el Top",
    fill = "Artista"
  ) +
  theme_minimal() +
  theme(
    plot.title = element_text(face = "bold", size = 16, color = "#1DB954"),
    plot.subtitle = element_text(size = 10, color = "gray40"),
    panel.grid.major.y = element_blank(),
    panel.grid.minor = element_blank(),
    axis.text = element_text(face = "bold"),
    legend.position = "right"
  )

# -------------------------------------------------------------
# 6. Extra: lista completa del Top 50 como tabla
# -------------------------------------------------------------

lista_top_50 <- data.frame(
  puesto = 1:50,
  cancion = sapply(top_tracks_50$items, function(x) x$name),
  artista = sapply(top_tracks_50$items, function(x) x$artists[[1]]$name),
  album = sapply(top_tracks_50$items, function(x) x$album$name)
)

View(lista_top_50)

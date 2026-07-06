# Docker helpers, enabled only when Docker exists.

if command -v docker >/dev/null 2>&1; then
    alias dps='docker ps'
    alias dpa='docker ps -a'
    alias di='docker images'
    alias dlog='docker logs -f'
    alias dex='docker exec -it'
    alias dcu='docker compose up -d'
    alias dcd='docker compose down'
    alias dcl='docker compose logs -f'
fi

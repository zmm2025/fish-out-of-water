# Fish Out of Water

A video game about a fish battling autism.

Developed with Drason and Max for Global Game Jam 2026.

## Deploying

The repo uses GitHub Actions to export the Godot Web build and deploy to GitHub Pages (see `.github/workflows/deploy-pages.yml`). For CI export to work, **`.godot/uid_cache.bin` must be committed** so Godot can resolve resource UIDs in headless export. If you open the project in the editor and the UID cache changes, commit it before pushing.

# GitHub Todos

GitHub Todos turns GitHub Projects V2 into a personal todo list. It is for people
who track work in GitHub issues and want a focused view of their daily tasks.

Connect with a GitHub Personal Access Token, then add personal or organization
projects. Browse and filter issues, set priorities and due dates through your
project's field mappings, create todos, close or reopen issues, and manage
comments. Changes sync with GitHub. Home Screen widgets on iOS and Android keep
tasks accessible outside the app.

## Deployment

GitHub Actions deploys the web app to Vercel on every push to `main`.
Release Please maintains a release PR; merging it creates a version tag and
GitHub release with a Linux AppImage. Release PRs also publish Linux previews
under `preview-pr-*` tags.

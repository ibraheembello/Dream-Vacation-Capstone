# Dream Vacations Capstone: Presentation

A walkthrough of the production deployment and the DevOps tooling behind it.

---

## 1. The problem

Dream Vacations has a full-stack app (React, Node, PostgreSQL) that runs on a
laptop. The job was to make it production ready: reproducible, automated,
deployed on AWS, and reachable over HTTPS on a real domain.

## 2. The solution at a glance

```
Developer push ─► GitHub Actions ─► GHCR images ─► Terraform (AWS) ─► EC2
                                                                        │
                    Route 53 zone + DuckDNS A record ─────────────►  Nginx + SSL
                                                                        │
                                                              https://dream-vacations.duckdns.org
```

One `git push` to `main` builds the images, provisions the infrastructure, and
rolls the app onto the server. Nothing is done by hand on the server.

## 3. Tools and why each was chosen

| Tool | Role | Why |
|------|------|-----|
| Git + GitHub | Version control, PR workflow | `main`/`dev` branches, branch protection, reviewable history |
| Bash | Automation scripts | Env setup, DB backups, log rotation; idempotent and cron-friendly |
| Docker | Containers | Same image runs locally and in production, no "works on my machine" |
| Docker Compose | Local + prod orchestration | One command brings up frontend, backend, and DB with networking |
| GitHub Actions | CI/CD | Tests and builds on PRs, publishes images and deploys on merge |
| Terraform | Infrastructure as code | The whole AWS stack is declarative, versioned, and reproducible |
| AWS (EC2, VPC, EIP, Route 53, CloudWatch) | Cloud platform | Compute, networking, DNS, and monitoring |
| Nginx | Reverse proxy | Single public entry point, serves the app and proxies the API |
| Certbot / Let's Encrypt | TLS certificates | Free, automated HTTPS with auto-renewal |
| DuckDNS | Free domain | Public hostname pointed at the Elastic IP |

## 4. Demo script (what to show live)

1. **Repo tour**: branches, branch protection, the four workflows, README badges.
2. **Local run**: `docker compose up --build`, open http://localhost:3000, add a
   destination.
3. **A pull request**: open a small PR into `main`, show CI running (lint, test,
   build) and blocking merge until green.
4. **Merge and deploy**: merge the PR, watch `deploy.yml` run the three stages
   (build, Terraform, deploy) in the Actions tab.
5. **Infrastructure**: in the AWS console show the VPC resource map, the EC2
   instance, the Route 53 hosted zone, and the CloudWatch CPU alarm.
6. **The live site**: open https://dream-vacations.duckdns.org, click the padlock
   to show the valid Let's Encrypt certificate, add a destination end to end.
7. **Operations**: run `scripts/db-backup.sh` on the box, show the dated dump and
   the retention pruning; show `certbot renew --dry-run` succeeding.

## 5. Talking points

- **Idempotency**: every shell script and the whole Terraform config can run
  repeatedly with the same result. Re-running never breaks a working system.
- **Least surprise on the server**: app containers bind to loopback only; the
  host Nginx is the one public door, and it terminates TLS.
- **Secrets stay out of git**: AWS keys, the SSH key, and the DB password live in
  GitHub Actions secrets, never in the repo.
- **Cost control**: a single `t3.micro`, one Elastic IP, and a small S3 state
  bucket. The free DuckDNS domain keeps DNS at zero cost.

## 6. What I would do next (stretch)

- Ship container and app logs to CloudWatch Logs with the CloudWatch agent.
- Add an autoscaling group and a load balancer for horizontal scale.
- Move the database to RDS with automated snapshots.
- Add a staging environment fed by the `dev` branch.

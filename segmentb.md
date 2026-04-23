## B1 

AI can be used to generate and maintain pipeline configuration by analyzing repository structure, language frameworks, and best practices.

### B1.1 Which AI tool would you use to generate the initial GitHub Actions YAML for a new service? Describe the prompt strategy you would use and how you validate the output before merging it.

**Tool:** Claude Code or Github Copilot 

**Prompt Strategy:**
- Provide context: language, framework, build tool, test command, artifact type.
- Specify deployment target (AWS ECS, Kubernetes, etc.).
- Define requirements: caching, secret handling, matrix builds, security scanning steps.
- Example: *“Generate a GitHub Actions workflow for a Node.js + Express service. Build with npm, run tests with Jest, scan with Trivy, deploy to AWS ECS Fargate. Include caching for node_modules and a manual approval step for production.
This is an example the structure that I expected from my pipeline: Install Dependecies from the language -> Create Test Stack with coverage and all test that exist on this directory -> Push the docker Image to the registry(Dockerhub) -> Create a Deploy strategie for this <service>
”*

**Validation before merging:**
- Run `yamllint` to check syntax.
- Execute in a dry-run mode (act tool or GitHub’s reusable workflows).
- Verify secrets are not hardcoded.
- Confirm step order and dependency graph.
- Manual review of any `uses:` actions for trusted sources.

### B1.2 How would you use AI to keep the pipeline up to date as runtimes, base images, and dependencies change over time? Describe what triggers the review, what the AI produces, and how a human approves or rejects it.

**Trigger:** Dependabot or Renovate PRs, scheduled monthly scan, or base image CVE alerts.

**AI produces:** A diff of the YAML showing updated versions, changed syntax, deprecated step replacements, and a short summary of why each change is needed.

**Human approval workflow:**
- AI creates a PR with the proposed pipeline updates.
- Human reviews changes, runs a test pipeline, checks logs for warnings.
- If approved → merge. If rejected → comment with reason, AI logs feedback for future tuning.

---

## B2

### B2.1 How would AI assist with generating or improving the deployment script? What would you always review manually before applying AI-generated deployment logic, and what would you never let AI decide on its own?

**Assistance:**
- Generate deployment scripts (Bash, Python) for blue-green or canary deployments.
- Suggest retry logic, rollback hooks, and environment variable validation.
- Optimize script idempotency and error handling.

**Always review manually:**
- Commands that modify infrastructure (e.g., `aws ecs update-service`, `kubectl apply`, `terraform apply`).
- Credential handling and secret injection.
- Rollback thresholds and timing.

**Never let AI decide on its own:**
- Which production environment to target.
- Auto-approving deployment without tests.
- Deleting resources or old versions.

### B2.2 Describe an AI-assisted rollback decision. What signals does it read, and where is the human in the loop?

**Signals read:**
- Health check failures (>5% error rate in 2 minutes)
- Latency spikes 
- Error logs (e.g., 5xx rates, database connection failures)
- Memory/CPU anomalies

**AI decision:** “Recommend immediate rollback to last known good version (v2.3.1) with 88% confidence.”

**Human in the loop:**
- AI sends alert with evidence and rollback command (preview).
- Human clicks “Approve Rollback” or “Override”.
- If no response in 3 minutes, auto-rollback only for critical SLO violations.

---

## B3

### B3.1 How would you use AI to generate the monitoring script and alert thresholds for a new service? Describe inputs and validation.

**Inputs to AI:**
- Service type (API, worker, database)
- Expected traffic patterns (peak hours, burst tolerance)
- SLIs/SLOs (e.g., latency <200ms for 99% requests)
- Existing monitoring stack (Prometheus, DataDog, CloudWatch)

**AI generates:**
- Script to deploy metric exporters (e.g., `prometheus_client`)
- Alert rules (YAML for Prometheus)
- Suggested thresholds (baseline + anomaly detection config)

**Validation before production:**
- Run script in staging with simulated load.
- Verify no duplicate alerts or missing critical metrics.
- Manually sanity-check thresholds (e.g., CPU 90% not too aggressive).
- Check that AI didn’t expose internal tokens.

---

## B4

### B4.1 Design an AI system for structured incident assessment.

**Model:** Fine-tuned LLaMA 3 (8B) or GPT-4 with function calling.

**Context input (last 15 minutes):**
- Log excerpts (error, warn)
- Metric time series (CPU, memory, latency, error rate)
- Recent deployment events
- Known service dependencies

**Output format (JSON):**
```json
{
  "incident_id": "inc-20250321-001",
  "probable_cause": "Database connection pool exhaustion",
  "affected_component": "payment-api",
  "recommended_action": "Restart payment-api pods and increase max_connections to 150",
  "confidence_level": 0.87
}
```

I will finetune a model because Pay for a model that is not focus on this will make the company pay a lot of money without be necessary.

The context of the logs are really big, so to make this happen we should improve the model context window to be abble to get logs and use the Fine-tuned model to work on solutions. We could alse create some agents to help this Fine-tuned model to get more and more precise on this.

### B4.2 Failure modes of this AI monitoring layer
| Failure Mode | Detection | Mitigation |
|--------------|-----------|-------------|
| Hallucination (false cause) | Compare AI output with known runbooks; flag if cause never seen before | Human confirmation required for confidence <0.9; log all hallucinations for retraining |
| Alert fatigue suppression (AI ignores real issue because it looks like past noise) | Monitor AI “no action” rate; sample 5% of ignored anomalies for human audit | Periodic replay of past incidents to test recall; ensemble with rule-based fallback |

## B5

### B5.1 How would you use AI to generate or audit Security Group rules, SSH config, and Docker non-root user setup?

**Generation:**
- Input: "Need SG for web app on port 443, DB port 3306 only from app subnet."
- AI outputs Terraform or AWS CLI commands.

**Audit:**
- AI reviews existing config for `0.0.0.0/0`, SSH password auth, root user in Docker.
- Flags violations with explanation.

**Mandatory human review step before applying:**
- SG rules allowing inbound from internet.
- Any SSH configuration change.
- Docker `USER` directive – human must verify the user exists and has correct permissions.

---

### B5.2 How would AI assist with interpreting Trivy or Checkov scan results?

**Workflow:**
1. Run Trivy/Checkov in CI.
2. AI classifies each finding: `CRITICAL` / `HIGH` / `MEDIUM` / `LOW` / `FALSE_POSITIVE`.
3. AI suggests fix (e.g., "update library X to v2.1.0").

**Flag table:**

| Finding type | AI action | Human required? |
|--------------|-----------|------------------|
| CRITICAL with public exploit | Suggest fix + auto-PR | No (auto-merge if tests pass) |
| HIGH with config change | Suggest fix, require approval | Yes |
| FALSE_POSITIVE | Suppress with comment | No, but logged |
| MEDIUM with no known exploit | Suggest deferral | No, but notify weekly |

---

## B6
### B6.1 Design an AI system for security event response.

**Model:** Lightweight classifier (XGBoost) + LLM for context explanation.

**Input events:**
- Failed SSH logins (>5 from same IP in 1m)
- Unexpected process starts (e.g., `nc`, `minerd`)
- Dependency scan alerts (new CVE)

**Output (JSON):**
```json
{
  "event_id": "sec-20250321-042",
  "threat_classification": "Brute force SSH attack",
  "affected_resource": "bastion-host-01",
  "recommended_action": "Add IP 203.0.113.89 to deny list in security group",
  "automation_level": "auto"
}
```


### B6.2 Which response actions are safe to automate fully, which require human approval before execution, and which should never be automated? Give at least one example in each category with your reasoning.

| Automation Category | Example Response Action | Reasoning |
|---------------------|------------------------|-----------|
| **Fully automated** | Block source IP after 5 failed SSH logins in 1 minute | Low risk of breakage; clear signature (repeated failed auth); action is reversible; no customer impact; reduces attacker dwell time |
| **Human approval required** | Kill a suspicious process (e.g., `minerd` or unknown network listener) | Could be false positive (e.g., legitimate backup job, monitoring agent); killing a process may disrupt service; human can verify process ancestry and hash before approving |
| **Never automate** | Delete an IAM role or user | Extreme impact (potential loss of all cloud access for a service or team); irreversible without manual recovery; requires security team audit, change request, and secondary sign-off |
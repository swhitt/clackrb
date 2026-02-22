#!/usr/bin/env ruby
# frozen_string_literal: true

# Ultimate Clack showcase — every impressive feature in one flow.
# Run with: ruby -Ilib examples/showcase.rb

require "clack"

Clack.intro "deploy-wizard"

# --- Text with tab completions ---
project = Clack.text(
  message: "Project name:",
  placeholder: "my-app",
  completions: %w[acme-api acme-web acme-admin acme-workers billing-service payment-gateway
    notification-hub auth-proxy data-pipeline analytics-engine search-indexer
    cdn-edge config-server feature-flags rate-limiter],
  validate: ->(v) { "Name is required" if v.to_s.strip.empty? }
)
exit 0 if Clack.cancel?(project)

# --- Autocomplete with fuzzy search (big list) ---
stack = Clack.autocomplete(
  message: "Tech stack:",
  placeholder: "Type to search...",
  options: [
    {value: "rails", label: "Ruby on Rails", hint: "full-stack, batteries included"},
    {value: "sinatra", label: "Sinatra", hint: "micro, DSL-style"},
    {value: "hanami", label: "Hanami", hint: "clean architecture"},
    {value: "roda", label: "Roda", hint: "routing tree"},
    {value: "grape", label: "Grape", hint: "API framework"},
    {value: "nextjs", label: "Next.js", hint: "React SSR"},
    {value: "nuxt", label: "Nuxt", hint: "Vue SSR"},
    {value: "sveltekit", label: "SvelteKit", hint: "Svelte SSR"},
    {value: "phoenix", label: "Phoenix", hint: "Elixir"},
    {value: "django", label: "Django", hint: "Python full-stack"},
    {value: "fastapi", label: "FastAPI", hint: "Python async"},
    {value: "express", label: "Express.js", hint: "Node.js minimal"},
    {value: "fastify", label: "Fastify", hint: "Node.js fast"},
    {value: "gin", label: "Gin", hint: "Go HTTP"},
    {value: "actix", label: "Actix Web", hint: "Rust async"},
    {value: "spring", label: "Spring Boot", hint: "Java enterprise"},
    {value: "laravel", label: "Laravel", hint: "PHP full-stack"}
  ]
)
exit 0 if Clack.cancel?(stack)

# --- Branching: choice determines follow-up ---
deploy_target = Clack.select(
  message: "Deploy target:",
  options: [
    {value: "kubernetes", label: "Kubernetes", hint: "container orchestration"},
    {value: "serverless", label: "Serverless", hint: "Lambda / Cloud Functions"},
    {value: "bare_metal", label: "Bare Metal", hint: "traditional VPS"}
  ]
)
exit 0 if Clack.cancel?(deploy_target)

case deploy_target
when "kubernetes"
  cloud = Clack.select(
    message: "Cloud provider:",
    options: [
      {value: "aws", label: "AWS EKS", hint: "Amazon"},
      {value: "gcp", label: "GCP GKE", hint: "Google"},
      {value: "azure", label: "Azure AKS", hint: "Microsoft"},
      {value: "do", label: "DigitalOcean DOKS"}
    ]
  )
  exit 0 if Clack.cancel?(cloud)

  replicas = Clack.range(
    message: "Pod replicas:",
    min: 1,
    max: 20,
    step: 1,
    initial_value: 3
  )
  exit 0 if Clack.cancel?(replicas)

when "serverless"
  cloud = Clack.select_key(
    message: "Serverless platform:",
    options: [
      {value: "lambda", label: "AWS Lambda", key: "a"},
      {value: "cloud_functions", label: "GCP Cloud Functions", key: "g"},
      {value: "azure_functions", label: "Azure Functions", key: "z"},
      {value: "cloudflare", label: "Cloudflare Workers", key: "c"}
    ]
  )
  exit 0 if Clack.cancel?(cloud)
  replicas = "auto"

when "bare_metal"
  cloud = "self-hosted"
  replicas = Clack.range(
    message: "Server count:",
    min: 1,
    max: 50,
    step: 1,
    initial_value: 2
  )
  exit 0 if Clack.cancel?(replicas)
end

# --- Group multiselect ---
addons = Clack.group_multiselect(
  message: "Add-ons:",
  selectable_groups: true,
  group_spacing: 1,
  options: [
    {
      label: "Observability",
      options: [
        {value: "prometheus", label: "Prometheus + Grafana"},
        {value: "datadog", label: "Datadog"},
        {value: "sentry", label: "Sentry", hint: "error tracking"}
      ]
    },
    {
      label: "Data",
      options: [
        {value: "postgres", label: "PostgreSQL"},
        {value: "redis", label: "Redis"},
        {value: "elasticsearch", label: "Elasticsearch"},
        {value: "kafka", label: "Kafka", hint: "event streaming"}
      ]
    },
    {
      label: "Security",
      options: [
        {value: "vault", label: "HashiCorp Vault", hint: "secrets"},
        {value: "oauth", label: "OAuth2 / OIDC"},
        {value: "waf", label: "WAF", hint: "web application firewall"}
      ]
    }
  ],
  required: false
)
exit 0 if Clack.cancel?(addons)

# --- Autocomplete multiselect ---
team = Clack.autocomplete_multiselect(
  message: "Notify team members:",
  options: [
    {value: "alice", label: "Alice Chen", hint: "backend"},
    {value: "bob", label: "Bob Martinez", hint: "frontend"},
    {value: "carol", label: "Carol Kim", hint: "SRE"},
    {value: "dave", label: "Dave Patel", hint: "security"},
    {value: "eve", label: "Eve Johansson", hint: "PM"},
    {value: "frank", label: "Frank Okafor", hint: "QA"},
    {value: "grace", label: "Grace Liu", hint: "data"},
    {value: "hank", label: "Hank Müller", hint: "DevOps"}
  ],
  required: false
)
exit 0 if Clack.cancel?(team)

# --- Date picker ---
deploy_date = Clack.date(
  message: "Target deploy date:",
  initial_value: Date.today + 7
)
exit 0 if Clack.cancel?(deploy_date)

# --- Confirm ---
go_live = Clack.confirm(
  message: "Schedule deployment?",
  initial_value: true
)
exit 0 if Clack.cancel?(go_live)

unless go_live
  Clack.outro "Deployment cancelled."
  exit 0
end

# --- Tasks with mid-task message updates ---
Clack.tasks(tasks: [
  {title: "Validating configuration", task: -> {
    sleep 0.6
  }},
  {title: "Provisioning infrastructure", task: ->(msg) {
    msg.call("Creating #{deploy_target} cluster...")
    sleep 0.8
    msg.call("Configuring networking...")
    sleep 0.5
    msg.call("Setting up DNS...")
    sleep 0.4
  }},
  {title: "Deploying #{project}", task: ->(msg) {
    msg.call("Building container image...")
    sleep 0.7
    msg.call("Pushing to registry...")
    sleep 0.5
    msg.call("Rolling out #{replicas} replicas...")
    sleep 0.6
  }},
  {title: "Running health checks", task: -> {
    sleep 0.8
  }}
])

# --- Summary ---
Clack.log.success "Deployment scheduled!"
Clack.log.step "Project: #{project}"
Clack.log.step "Stack: #{stack}"
Clack.log.step "Target: #{deploy_target} (#{cloud})"
Clack.log.step "Replicas: #{replicas}"
Clack.log.step "Add-ons: #{addons.join(", ")}" unless addons.empty?
Clack.log.step "Team: #{team.join(", ")}" unless team.empty?
Clack.log.step "Deploy date: #{deploy_date}"

Clack.note <<~MSG, title: "What happens next"
  1. CI pipeline will run at #{deploy_date}
  2. Canary deploy to 10% traffic
  3. Full rollout after 30min soak
  4. Team notified via Slack
MSG

Clack.outro "Happy shipping!"

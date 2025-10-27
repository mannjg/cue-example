// Package services defines the application-specific configuration
// This file contains all application-specific elements like volumes, mounts,
// environment variables, and ports, while leaving instance-specific values
// (image, replicas, resources) to be provided by environment files
package services

import "example.com/cue-example/k8s"

// #AppConfig defines the schema for instance-specific configuration
// These values must be provided by environment files (dev.cue, stage.cue, prod.cue)
#AppConfig: {
	// Container image with tag (e.g., "myapp:v1.2.3")
	image: string

	// Number of pod replicas
	replicas: int & >=1

	// Resource requests and limits
	resources: k8s.#Resources

	// Optional node selector for pod placement
	nodeSelector?: [string]: string

	// Optional custom namespace (can override default)
	namespace?: string
}

// appConfig is a constraint that environment files must satisfy
// The constraint limits replicas to a reasonable range
appConfig: #AppConfig & {
	replicas: >=1 & <=10
}

// deployment defines the actual Kubernetes Deployment resource
// It uses #Deployment schema from deployment.cue and fills in all
// application-specific configuration while referencing appConfig
// for instance-specific values
deployment: k8s.#Deployment & {
	metadata: {
		name: "myapp"
		// Use namespace from appConfig if provided, otherwise default
		if appConfig.namespace != _|_ {
			namespace: appConfig.namespace
		}
		labels: {
			app:       "myapp"
			component: "backend"
			managed:   "cue"
		}
	}

	spec: {
		// Instance-specific: provided by env files
		replicas: appConfig.replicas

		// Selector must match template labels
		selector: matchLabels: {
			app:       "myapp"
			component: "backend"
		}

		// Rolling update strategy with safe defaults
		strategy: {
			type: "RollingUpdate"
			rollingUpdate: {
				maxSurge:       1
				maxUnavailable: 0
			}
		}

		template: {
			metadata: {
				labels: {
					app:       "myapp"
					component: "backend"
					managed:   "cue"
				}
				annotations: {
					"prometheus.io/scrape": "true"
					"prometheus.io/port":   "8080"
					"prometheus.io/path":   "/metrics"
				}
			}

			spec: {
				// Main application container
				containers: [{
					name: "myapp"

					// Instance-specific: provided by env files
					image: appConfig.image

					// Always pull to ensure latest tag is used
					imagePullPolicy: "Always"

					// Application listens on port 8080
					ports: [{
						name:          "http"
						containerPort: 8080
						protocol:      "TCP"
					}]

					// Application-specific environment variables
					// Mix of direct values and references to secrets
					env: [
						{
							name:  "APP_ENV"
							value: "production"
						},
						{
							name:  "APP_PORT"
							value: "8080"
						},
						{
							name:  "DATABASE_HOST"
							value: "postgres.database.svc.cluster.local"
						},
						{
							name:  "DATABASE_PORT"
							value: "5432"
						},
						{
							name:  "DATABASE_NAME"
							value: "myapp"
						},
						{
							name: "DATABASE_USER"
							valueFrom: secretKeyRef: {
								name: "myapp-secrets"
								key:  "db-user"
							}
						},
						{
							name: "DATABASE_PASSWORD"
							valueFrom: secretKeyRef: {
								name: "myapp-secrets"
								key:  "db-password"
							}
						},
						{
							name: "REDIS_URL"
							valueFrom: configMapKeyRef: {
								name: "myapp-config"
								key:  "redis-url"
							}
						},
						{
							name: "LOG_LEVEL"
							valueFrom: configMapKeyRef: {
								name: "myapp-config"
								key:  "log-level"
							}
						},
					]

					// Application-specific volume mounts
					volumeMounts: [
						{
							name:      "data"
							mountPath: "/var/lib/myapp/data"
							readOnly:  false
						},
						{
							name:      "config"
							mountPath: "/etc/myapp/config"
							readOnly:  true
						},
						{
							name:      "cache"
							mountPath: "/var/cache/myapp"
							readOnly:  false
						},
					]

					// Instance-specific: provided by env files
					resources: appConfig.resources

					// Health checks
					livenessProbe: {
						httpGet: {
							path:   "/health/live"
							port:   8080
							scheme: "HTTP"
						}
						initialDelaySeconds: 30
						periodSeconds:       10
						timeoutSeconds:      5
						failureThreshold:    3
					}

					readinessProbe: {
						httpGet: {
							path:   "/health/ready"
							port:   8080
							scheme: "HTTP"
						}
						initialDelaySeconds: 10
						periodSeconds:       5
						timeoutSeconds:      3
						failureThreshold:    3
					}

					// Security context for container
					securityContext: {
						runAsNonRoot:             true
						runAsUser:                1000
						runAsGroup:               1000
						readOnlyRootFilesystem:   false
						allowPrivilegeEscalation: false
						capabilities: {
							drop: ["ALL"]
						}
					}
				}]

				// Application-specific volumes
				volumes: [
					{
						name: "data"
						persistentVolumeClaim: {
							claimName: "myapp-data"
						}
					},
					{
						name: "config"
						configMap: {
							name: "myapp-config"
						}
					},
					{
						name: "cache"
						emptyDir: {
							medium: "Memory"
							sizeLimit: "256Mi"
						}
					},
				]

				// Instance-specific: optional node selector from env files
				if appConfig.nodeSelector != _|_ {
					nodeSelector: appConfig.nodeSelector
				}

				// Pod-level security context
				securityContext: {
					runAsNonRoot: true
					runAsUser:    1000
					runAsGroup:   1000
					fsGroup:      1000
				}

				// Service account for the application
				serviceAccountName: "myapp"
			}
		}
	}
}

// service defines the Kubernetes Service resource
// Exposes the application deployment via a ClusterIP service
service: k8s.#Service & {
	metadata: {
		name: "myapp"
		// Use same namespace as deployment
		if appConfig.namespace != _|_ {
			namespace: appConfig.namespace
		}
		labels: {
			app:       "myapp"
			component: "backend"
			managed:   "cue"
		}
	}

	spec: {
		type: "ClusterIP"

		// Select pods with matching labels
		selector: {
			app:       "myapp"
			component: "backend"
		}

		// Expose HTTP port
		ports: [{
			name:       "http"
			protocol:   "TCP"
			port:       80
			targetPort: 8080
		}]

		// Sticky sessions based on client IP
		sessionAffinity: "None"
	}
}

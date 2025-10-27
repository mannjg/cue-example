// Package services defines the application-specific configuration for foo
// This file contains all application-specific elements like volumes, mounts,
// environment variables, and ports, while leaving instance-specific values
// (image, replicas, resources) to be provided by environment files
package services

import "example.com/cue-example/k8s"

// foo application configuration
foo: {

	// appName defines the application name used throughout the configuration
	// Change this value to customize for a different application
	appName: "foo"

	// defaultNamespace is the app-level default namespace
	// Can be overridden by environment files via appConfig.namespace
	// If not overridden, uses this value; if this is not set, falls back to k8s schema default "default"
	defaultNamespace: "foo-namespace"

	// resources_list defines which Kubernetes resources this app includes
	// This list is used by generate-manifests.sh to dynamically export resources
	resources_list: ["deployment", "service"]
	
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
	
		// Namespace can be overridden by environment
		namespace?: string
	}

	// appConfig is a constraint that environment files must satisfy
	// The constraint limits replicas to a reasonable range and provides app-level namespace default
	appConfig: #AppConfig & {
		replicas:  >=1 & <=10
		namespace: string | *defaultNamespace
	}
	
	// deployment defines the actual Kubernetes Deployment resource
	// It uses #Deployment schema from deployment.cue and fills in all
	// application-specific configuration while referencing appConfig
	// for instance-specific values
	deployment: k8s.#Deployment & {
		let ns = appConfig.namespace
		metadata: {
			name:      appName
			namespace: ns
			labels: {
				app:       appName
				component: "backend"
				managed:   "cue"
			}
		}
	
		spec: {
			// Instance-specific: provided by env files
			replicas: appConfig.replicas
	
			// Selector must match template labels
			selector: matchLabels: {
				app:       appName
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
						app:       appName
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
						name: appName
	
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
								value: appName
							},
							{
								name: "DATABASE_USER"
								valueFrom: secretKeyRef: {
									name: "\(appName)-secrets"
									key:  "db-user"
								}
							},
							{
								name: "DATABASE_PASSWORD"
								valueFrom: secretKeyRef: {
									name: "\(appName)-secrets"
									key:  "db-password"
								}
							},
							{
								name: "REDIS_URL"
								valueFrom: configMapKeyRef: {
									name: "\(appName)-config"
									key:  "redis-url"
								}
							},
							{
								name: "LOG_LEVEL"
								valueFrom: configMapKeyRef: {
									name: "\(appName)-config"
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
								claimName: "\(appName)-data"
							}
						},
						{
							name: "config"
							configMap: {
								name: "\(appName)-config"
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
					serviceAccountName: appName
				}
			}
		}
	}
	
	// service defines the Kubernetes Service resource
	// Exposes the application deployment via a ClusterIP service
	service: k8s.#Service & {
		let ns = appConfig.namespace
		metadata: {
			name:      appName
			namespace: ns
			labels: {
				app:       appName
				component: "backend"
				managed:   "cue"
			}
		}
	
		spec: {
			type: "ClusterIP"
	
			// Select pods with matching labels
			selector: {
				app:       appName
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
}

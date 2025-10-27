// Package services provides shared application templates and patterns
// This file contains reusable definitions to eliminate duplication across apps
package services

import (
	"example.com/cue-example/k8s"
	"list"
)

// #AppBase defines the complete application configuration template
// Apps instantiate this with their specific appName and customizations
#AppBase: {
	// Allow apps to add additional fields (e.g., configmap for bar)
	...

	// appName must be provided by the app
	appName: string

	// defaultNamespace is the app-level default namespace
	// Can be overridden by environment files via appConfig.namespace
	defaultNamespace: string | *"\(appName)-namespace"

	// defaultLabels defines the app-level default labels applied to all resources
	// Can be extended or overridden by environment files via appConfig.labels
	defaultLabels: {
		app:       appName
		component: "backend"
		managed:   "cue"
	}

	// defaultEnvFrom defines the app-level default environment variable sources
	// Can be extended by environment files via appConfig.envFrom
	defaultEnvFrom: [
		{
			configMapRef: {
				name: "\(appName)-config"
			}
		},
		{
			secretRef: {
				name: "\(appName)-secrets"
			}
		},
	]

	// defaultEnv defines the app-level default individual environment variables
	// Can be extended by apps or environments via appConfig.additionalEnv
	defaultEnv: [
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

	// resources_list defines which Kubernetes resources this app includes
	// This list is used by generate-manifests.sh to dynamically export resources
	// Default includes deployment and service; apps can override to add more (e.g., configmap)
	resources_list: [...string] | *["deployment", "service"]

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

		// Labels can be extended or overridden by environment
		labels?: [string]: string

		// Additional envFrom sources to append to defaults
		// Environments specify additional sources here, not the complete list
		// Defaults to empty list if not specified
		additionalEnvFrom: [...k8s.#EnvFromSource] | *[]

		// Additional individual env vars to append to defaults
		// Apps or environments specify additional vars here, not the complete list
		// Defaults to empty list if not specified
		additionalEnv: [...k8s.#EnvVar] | *[]

		// Volume source names - can be overridden per environment
		volumeSourceNames?: {
			configMapName?: string
			secretName?:    string
		}

		// Optional liveness probe override
		// Apps or environments can override the entire probe or specific fields
		livenessProbe?: k8s.#Probe

		// Optional readiness probe override
		// Apps or environments can override the entire probe or specific fields
		readinessProbe?: k8s.#Probe

		// Optional container ports override
		// Apps or environments can override to expose different/additional ports
		containerPorts?: [...k8s.#ContainerPort]

		// Optional service ports override
		// Apps or environments can override to expose different service ports
		servicePorts?: [...k8s.#ServicePort]
	}

	// appConfig is a constraint that environment files must satisfy
	// The constraint limits replicas to a reasonable range and provides app-level defaults
	appConfig: #AppConfig & {
		replicas:  >=1 & <=10
		namespace: string | *defaultNamespace
		labels: {
			defaultLabels  // Include default labels
			...            // Allow environments to add or override
		}
	}

	// Volume source names with defaults that can be overridden by environments
	// Default values are merged with any overrides from appConfig
	#DefaultVolumeSourceNames: {
		configMapName: *"\(appName)-config" | string
		secretName:    *"\(appName)-secrets" | string
	}

	volumeSourceNames: #DefaultVolumeSourceNames & {
		if appConfig.volumeSourceNames != _|_ {
			if appConfig.volumeSourceNames.configMapName != _|_ {
				configMapName: appConfig.volumeSourceNames.configMapName
			}
			if appConfig.volumeSourceNames.secretName != _|_ {
				secretName: appConfig.volumeSourceNames.secretName
			}
		}
	}

	// envFrom combines defaults with environment-specific additions
	envFrom: list.Concat([defaultEnvFrom, appConfig.additionalEnvFrom])

	// env combines default individual vars with app/environment-specific additions
	env: list.Concat([defaultEnv, appConfig.additionalEnv])

	// deployment defines the actual Kubernetes Deployment resource
	deployment: k8s.#Deployment & {
		let ns = appConfig.namespace
		let envFromSources = envFrom
		let envVars = env
		metadata: {
			name:      appName
			namespace: ns
			labels:    appConfig.labels
		}

		spec: {
			replicas: appConfig.replicas

			selector: matchLabels: {
				app:       appName
				component: "backend"
			}

			strategy: {
				type: "RollingUpdate"
				rollingUpdate: {
					maxSurge:       1
					maxUnavailable: 0
				}
			}

			template: {
				metadata: {
					labels: appConfig.labels
					annotations: {
						"prometheus.io/scrape": "true"
						"prometheus.io/port":   "8080"
						"prometheus.io/path":   "/metrics"
					}
				}

				spec: {
					containers: [{
						name:            appName
						image:           appConfig.image
						imagePullPolicy: "Always"

						// Container ports with overridable defaults
						// Apps or environments can override via appConfig.containerPorts
						ports: appConfig.containerPorts | *[{
							name:          "http"
							containerPort: 8080
							protocol:      "TCP"
						}]

						// Environment variable sources from ConfigMaps and Secrets
						envFrom: envFromSources

						// Application-specific environment variables
						// Combines defaultEnv with app/environment-specific additionalEnv
						env: envVars
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
							{
								name:      "projected-secrets"
								mountPath: "/var/secrets"
								readOnly:  true
							},
						]

						resources: appConfig.resources

						// Liveness probe with overridable defaults
						// Apps or environments can override via appConfig.livenessProbe
						livenessProbe: appConfig.livenessProbe | *{
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

						// Readiness probe with overridable defaults
						// Apps or environments can override via appConfig.readinessProbe
						readinessProbe: appConfig.readinessProbe | *{
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
								medium:    "Memory"
								sizeLimit: "256Mi"
							}
						},
						{
							name: "projected-secrets"
							projected: {
								defaultMode: 0o400
								sources: [
									{
										secret: {
											name: volumeSourceNames.secretName
											items: [
												{
													key:  "db-user"
													path: "database/username"
												},
												{
													key:  "db-password"
													path: "database/password"
												},
											]
										}
									},
									{
										configMap: {
											name: volumeSourceNames.configMapName
											items: [
												{
													key:  "redis-url"
													path: "config/redis-url"
												},
											]
										}
									},
									{
										downwardAPI: {
											items: [
												{
													path: "pod/name"
													fieldRef: {
														fieldPath: "metadata.name"
													}
												},
												{
													path: "pod/namespace"
													fieldRef: {
														fieldPath: "metadata.namespace"
													}
												},
											]
										}
									},
								]
							}
						},
					]

					if appConfig.nodeSelector != _|_ {
						nodeSelector: appConfig.nodeSelector
					}

					securityContext: {
						runAsNonRoot: true
						runAsUser:    1000
						runAsGroup:   1000
						fsGroup:      1000
					}

					serviceAccountName: appName
				}
			}
		}
	}

	// service defines the Kubernetes Service resource
	service: k8s.#Service & {
		let ns = appConfig.namespace
		metadata: {
			name:      appName
			namespace: ns
			labels:    appConfig.labels
		}

		spec: {
			type: "ClusterIP"

			selector: {
				app:       appName
				component: "backend"
			}

			// Service ports with overridable defaults
			// Apps or environments can override via appConfig.servicePorts
			ports: appConfig.servicePorts | *[{
				name:       "http"
				protocol:   "TCP"
				port:       80
				targetPort: 8080
			}]

			sessionAffinity: "None"
		}
	}
}

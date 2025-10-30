// Package envs provides staging environment configuration
// This file contains concrete values for staging instances
package envs

import (
	apps "example.com/cue-example/services/apps"
	base "example.com/cue-example/services/base"
)

// Bring service definitions into this package with explicit references
foo: apps.foo
bar: apps.bar
baz: apps.baz

// Environment-level defaults shared by all apps in staging
// Apps can reference these values and override them if needed
_envDefaults: {
	namespace: "staging"

	deployment: {
		clusterCAConfigMap: "stage-cluster-ca"
		replicas:           2

		// Common staging resource limits - production-like but more conservative
		resources: base.#DefaultStageResources
	}
}

// Staging environment configuration for foo app
// Production-like environment for testing and validation before promoting to production
foo: {
	// Setup renderer with stage-specific input values
	_renderer: apps.#FooRenderer & {
		inputs: {
			// Scalar inputs for transformation
			apiKey:      "stage-api-key-67890"
			dbUrl:       "postgres://stage-db.example.com:5432/foo_stage"
			enableCache: true
			logLevel:    "info"
			maxRetries:  3

			// Pass complete appConfig as input to renderer
			appConfig: {
				// Use environment-level defaults for common settings
				_envDefaults

				// Debug mode disabled for foo in staging (default is false)

				deployment: {
					// Use stage-specific image tag - typically built from release candidate or main branch
					image: "foo:stage-v1.2.3-rc1"

					// Override volume source names for staging environment
					volumeSourceNames: {
						configMapName: "foo-stage-config"
						secretName:    "foo-stage-secrets"
					}
				}
			}
		}
	}

	// Use rendered config directly - no additional merging needed!
	appConfig: _renderer.renderedConfig
}

// Staging environment configuration for bar app
bar: {
	appConfig: {
		// Use environment-level defaults for common settings
		_envDefaults

		// Debug mode disabled for bar in staging (default is false)

		deployment: {
			// Use stage-specific image tag
			image: "bar:stage-v1.2.3-rc1"
		}
	}

	// ConfigMap is automatically generated from appConfig.configMap
}

// Staging environment configuration for baz app
baz: appConfig: {
	// Use environment-level defaults for common settings
	_envDefaults

	// Enable debug mode for baz in staging for testing
	// Automatically adds debug port (5005) and creates separate debug service
	// Demonstrates that different apps can have different debug settings per environment
	debug: true

	deployment: {
		// Use stage-specific image tag
		image: "baz:stage-v1.2.3-rc1"
	}
}

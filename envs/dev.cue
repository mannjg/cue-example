// Package envs provides development environment configuration
// This file contains concrete values for development instances
package envs

import (
	apps "example.com/cue-example/services/apps"
	base "example.com/cue-example/services/base"
)

// Bring service definitions into this package with explicit references
// This makes the configuration flow clearer and more maintainable
foo: apps.foo
bar: apps.bar
baz: apps.baz

// Environment-level defaults shared by all apps in development
// Apps can reference these values and override them if needed
_envDefaults: {
	namespace: "dev"

	deployment: {
		clusterCAConfigMap: "dev-cluster-ca"

		// Common development resource limits
		resources: base.#DefaultDevResources
	}
}

// Development environment configuration for foo app
// Optimized for fast iteration and minimal resource usage
foo: {
	// Setup renderer with dev-specific input values
	// Renderer logic lives in apps.#FooRenderer (not duplicated here)
	_renderer: apps.#FooRenderer & {
		inputs: {
			// Scalar inputs for transformation
			apiKey:      "dev-api-key-12345"
			dbUrl:       "postgres://dev-db.local:5432/foo_dev"
			enableCache: true
			logLevel:    "debug"
			maxRetries:  5

			// Pass complete appConfig as input to renderer
			appConfig: {
				// Use environment-level defaults for common settings
				_envDefaults

				// Enable debug mode for development troubleshooting
				// Automatically adds debug port (5005) and creates separate debug service
				debug: true

				deployment: {
					// Use latest dev image for rapid iteration
					image: "foo:dev-latest"

					// Single replica for development
					replicas: 1
				}
			}
		}
	}

	// Use rendered config directly - no additional merging needed!
	appConfig: _renderer.renderedConfig
}

// Development environment configuration for bar app
// Optimized for fast iteration and minimal resource usage
bar: {
	appConfig: {
		// Use environment-level namespace default
		namespace: _envDefaults.namespace

		// Debug mode disabled for bar (default is false)

		deployment: {
			// Use latest dev image for rapid iteration
			image: "bar:dev-latest"

			// Single replica for development
			replicas: 1

			// Use environment-level resource defaults
			resources: _envDefaults.deployment.resources

			// Override environment default with app-specific cluster CA ConfigMap
			// Demonstrates per-app override capability
			clusterCAConfigMap: "bar-custom-dev-ca"
		}
	}

	// ConfigMap is automatically generated from appConfig.configMap
}

// Development environment configuration for baz app
// Optimized for fast iteration and minimal resource usage
baz: appConfig: {
	// Use environment-level defaults for common settings
	_envDefaults

	// Debug mode disabled for baz (default is false)

	deployment: {
		// Use latest dev image for rapid iteration
		image: "baz:dev-latest"

		// Single replica for development
		replicas: 1
	}
}

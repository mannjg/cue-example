// Package apps defines the application-specific configuration for foo
// This file is self-contained with both the app definition and its renderer
package apps

import (
	"encoding/json"
	core "example.com/cue-example/services/core"
)

// foo application configuration
// Uses the #App template with foo-specific settings
foo: core.#App & {
	// Set the application name
	appName: "foo"

	// Enable HTTPS for all foo instances across all environments
	appConfig: {
		enableHttps: true
	}

	// All other configuration comes from environment files via appConfig
	// The namespace defaults to "foo-namespace" but can be overridden
	// Resources are automatically managed (deployment, service, and debugService when debug=true)
}

// #FooRenderer defines how foo's appConfig fields are generated from environment inputs
// Environments pass appConfig as an input, and the renderer merges it with generated config
// This renderer is specific to foo and lives alongside the foo app definition
#FooRenderer: {
	// Inputs that environments must provide
	inputs: {
		// Scalar inputs for transformation
		apiKey:      string
		dbUrl:       string
		enableCache: bool
		logLevel:    string
		maxRetries:  int

		// Environment-specific appConfig to merge with generated config
		// Can include _envDefaults, debug, deployment overrides, etc.
		appConfig: {...}
	}

	// Base configuration structure (always present)
	// This contains all non-conditional fields
	_base: {
		api: {
			key:      inputs.apiKey
			endpoint: "https://api.example.com/v1"
			timeout:  30
			retries:  inputs.maxRetries
		}
		database: {
			url:         inputs.dbUrl
			poolSize:    20
			maxLifetime: 3600
		}
		logging: {
			level:  inputs.logLevel
			format: "json"
		}
	}

	// Conditional cache configuration
	// This struct is empty by default, but populated when cache is enabled
	// Key insight: the conditional operates on a separate struct that gets merged
	_cache: {}
	if inputs.enableCache {
		_cache: {
			cache: {
				enabled: true
				ttl:     300
				backend: "redis"
			}
		}
	}

	// Final merged configuration
	// Combines base config with any conditional features
	config: _base & _cache

	// Generated ConfigMap structure
	_generated: {
		configMap: data: {
			// Complex JSON structure generated from config
			"app-config.json": json.Marshal(config)

			// YAML format for logging configuration
			"logging.yaml": """
				level: \(inputs.logLevel)
				handlers:
				  console:
				    class: StreamHandler
				    level: \(inputs.logLevel)
				    format: '%(asctime)s - %(name)s - %(levelname)s - %(message)s'
				"""

			// Simple text file with environment info
			"environment.txt": """
				Log Level: \(inputs.logLevel)
				Retries: \(inputs.maxRetries)
				"""
		}
	}

	// Final rendered config: merge environment-provided appConfig with generated config
	// Environments simply use: appConfig: _renderer.renderedConfig
	renderedConfig: inputs.appConfig & _generated
}

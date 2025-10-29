// Package services defines the application-specific configuration for foo
// This file instantiates the shared application template with foo-specific settings
package apps

import core "example.com/cue-example/services/core"

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

// Package services defines the application-specific configuration for foo
// This file instantiates the shared application template with foo-specific settings
package services

// foo application configuration
// Uses the #App template with foo-specific settings
foo: #App & {
	// Set the application name
	appName: "foo"

	// All other configuration comes from environment files via appConfig
	// The namespace defaults to "foo-namespace" but can be overridden
	// Resources are automatically managed (deployment, service, and debugService when debug=true)
}

// Package services defines the application-specific configuration for foo
// This file instantiates the shared application template with foo-specific settings
package services

// foo application configuration
// Uses the #AppBase template from _base.cue with foo-specific customizations
foo: #AppBase & {
	// Set the application name
	appName: "foo"

	// Use default namespace pattern: "foo-namespace"
	// Can be overridden by environments via appConfig.namespace

	// Resources exported for this app: deployment and service
	// This is the default from #AppBase, explicitly shown here for clarity
	resources_list: ["deployment", "service"]
}

// Package services defines the application-specific configuration for bar
// This file instantiates the shared application template with bar-specific settings
package services

// bar application configuration
// Uses the #App template with bar-specific customizations
bar: #App & {
	// Set the application name
	appName: "bar"

	// Bar has app-level defaults for configMapData
	// This demonstrates the new configMapData capability pattern
	// The ConfigMap resource, volume, and mount are automatically wired together
	appConfig: {
		configMapData: {
			data: {
				"redis-url": string | *#DefaultRedisURL
				"log-level": string | *#DefaultLogLevel
			}
			// Use default mount settings (/etc/app-config, readOnly: true)
		}
		// Allow environments to add or override
		...
	}
}

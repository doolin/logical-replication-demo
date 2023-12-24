#!/usr/bin/perl

use strict;
use warnings;
use LWP::UserAgent;
use JSON;

# Grafana API details
my $grafana_host = "your-grafana-host:3000";
my $api_key = "YOUR_GRAFANA_API_KEY";

# Dashboard JSON
my $dashboard_json = {
    dashboard => {
        id => undef,
        uid => undef,
        title => "Flux Query Dashboard",
        panels => [{
            title => "Flux Query Panel",
            type => "graph",
            targets => [{
                datasource => "YourInfluxDBDataSourceName",
                refId => "A",
                query => "from(bucket: \"ruby_test\") |> range(start: v.timeRangeStart, stop: v.timeRangeStop) |> filter(fn: (r) => r[\"_measurement\"] == \"locks\") |> filter(fn: (r) => r[\"_field\"] == \"lock_count\") |> filter(fn: (r) => r[\"mode\"] == \"AccessShareLock\" or r[\"mode\"] == \"ExclusiveLock\" or r[\"mode\"] == \"RowExclusiveLock\" or r[\"mode\"] == \"ShareLock\" or r[\"mode\"] == \"ShareUpdateExclusiveLock\")",
                format => "time_series"
            }],
            gridPos => { h => 9, w => 24, x => 0, y => 0 }
        }],
        schemaVersion => 16,
        version => 0
    },
    overwrite => JSON::false,
};

# Setup user agent
my $ua = LWP::UserAgent->new;
$ua->default_header('Authorization' => "Bearer $api_key");
$ua->default_header('Content-Type' => 'application/json');

# API URL
my $api_url = "http://$grafana_host/api/dashboards/db";

# Make the API request
my $response = $ua->post($api_url, Content => encode_json($dashboard_json));

# Check the response
if ($response->is_success) {
    print "Dashboard created successfully.\n";
} else {
    print "Failed to create dashboard. HTTP response code: " . $response->code . "\n";
    print "Response content: " . $response->decoded_content . "\n";
}


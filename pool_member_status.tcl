when HTTP_REQUEST {
	if { [HTTP::uri] == "/" || [HTTP::uri] eq "/status" } {
		## log local0. "Here is the list   $::pool_member_status_list"
		set myHostName $static::tcl_platform(machine)
		set response "<!DOCTYPE html><html><head><title>$myHostName Pool Member Status - "
		append response [clock format [clock seconds]]
		append response "</title><meta http-equiv=\"refresh\" content=\"300; url=http://[HTTP::host]/status\" /><meta name=\"viewport\" content=\"width=device-width\" /><style>[ifile get f5.bootstrap.css]</style><script type=\"text/javascript\">[ifile get f5.modernizr.js]</script></head><body><div class=\"container\"><h2>$myHostName Pool Member Status <small>-  [clock format [clock seconds]]</small></h2><table class=\"table table-bordered table-striped table-hover table-condensed\"><thead><tr><th style=\"text-align:center\">Status</th><th>Pool Name</th><th>Member</th><th>Port</th></tr></thead><tbody>"  
		
		foreach { selectedpool } [class get pool_member_status_list] {
			if { [catch {
				scan $selectedpool {%[^/]/%[^:]:%s} poolname addr port  
				switch -glob [LB::status pool $poolname member $addr $port] {
					"up" {
						append response "<tr class=\"success\"><td style=\"text-align:center\"><span class=\"badge badge-success\"><b>UP</b></span></td>\
						<td>[string tolower $poolname]</td><td>$addr</td><td>$port</td><tr>"
					}
					"down" { 
						append response "<tr class=\"error\"><td style=\"text-align:center\"><span class=\"badge badge-important\"><b>DOWN</b></span></td>\
						<td>[string tolower $poolname]</<d><td>$addr</td><td>$port</td><tr>"
					}
					"session_enabled" { 
						append response "<tr class=\"info\"><td style=\"text-align:center\"><span class=\"badge badge-info\"><b>ENABLED</b></span></td>\
						<td>[string tolower $poolname]</td><td>$addr</td><td>$port</td><tr>"
					}
					"session_disabled" { 
						append response "<tr><td style=\"text-align:center\"><span class=\"badge badge-inverse\"><b>DISABLED</b></span></td>\
						<td>[string tolower $poolname]</td><td>$addr</td><td>$port</td><tr>"
					}
					Default {
						append response "<tr class=\"warning\"><td style=\"text-align:center\"><span class=\"badge badge-warning\"><b>ERR: STATUS</b></span></td>\
						<td>[string tolower $poolname]</td><td>$addr</td><td>$port</td><tr>"
					}
				}
				#SWITCH END
			} errmsg] } { 
			append response "<tr><td style=\"text-align:center\"><span class=\"badge badge-warning\"><b>ERR: GLOB</b></span></td><td>[string tolower $poolname]</td><td>$addr</td><td>$port</td><tr>"
			}
		}
		#FOR LOOP END
		append response "</tbody></table><hr><footer><p>&copy; ABC 123</p></footer></div> <!-- /container --><script type=\"text/javascript\">[ifile get f5.jquery.js]</script><script type=\"text/javascript\">[ifile get f5.bootstrap.js]</script></body></html>"  
		HTTP::respond 200 content $response "Content-Type" "text/html" "Content-Type" "text/html" "Cache-Control" "no-cache, must-revalidate"
	}
	# END [HTTP::uri] eq "/status" END
	if { [HTTP::uri] eq "/rss" } {
		set myHostName $static::tcl_platform(machine)
		set response "<?xml version=\"1.0\" encoding=\"utf-8\"?><rss version=\"2.0\"><channel>"
		append response "<title>$myHostName Pool Member Status Pool Member Status</title><description>Server Pool Status</description>"
		append response "<language>en</language><pubDate>[clock format [clock seconds]]</pubDate>\<ttl>60</ttl>"
		foreach { selectedpool } [class get pool_member_status_list] {
			if { [catch {
				scan $selectedpool {%[^/]/%[^:]:%s} poolname addr port  
				switch -glob [LB::status pool $poolname member $addr $port] {
					"up" {
						append response "<item><title>[string tolower $poolname] Status</title><description>"
						append response "Member $addr:$port is <b><font style=\"color:green\">UP</font></b></description></item>"
					}
					"down" { 
						append response "<item><title>[string tolower $poolname] Status</title><description>"
						append response "Member $addr:$port is <b><font style=\"color:red\">DOWN</font></b></description></item>"
					}
					"session_enabled" { 
						append response "<item><title>[string tolower $poolname] Status</title><description>"
						append response "Member $addr:$port is <b><font style=\"color:blue\">ENABLED</font></b></description></item>"
					}
					"session_disabled" { 
						append response "<item><title>[string tolower $poolname] Status</title><description>"
						append response "Member $addr:$port is <b><font style=\"color:black\">DISABLED</font></b></description></item>"
					}
					Default {
						append response "<item><title>[string tolower $poolname] Status</title><description>"
						append response "Member $addr:$port is <b><font style=\"color:orange\">INVALID</font></b></description></item>"
					}
				}
				#SWITCH END
			} errmsg] } {
			append response "<item><title>[string tolower $poolname] Status</title><description>Member $addr:$port is "
			append response "<b><font style=\"color:orange\">INVALID</font></b></description></item>"
			}
			#SECOND CONDITIONAL STATEMENT END - Catch end error in an invalid named or non-existant pool
		}
		#FOR LOOP END
		append response "</channel></rss>"
		HTTP::respond 200 content $response "Content-Type" "text/xml"
	}
	# END [HTTP::uri] eq "/rss" END
}

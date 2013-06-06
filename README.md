# Pool-Member-Status-List

F5 BIG-IP Pool Member Status Lookup Webpage

## Synopsys

This bash script and iRule will generate a webpage for a specified VIP on an F5 BIG-IP that will step through all pool members and return their status: up, down, enabled, disabled.

### External Assets

This iRule assumes you have defined four iFiles, being the four basic style management files from the Twitter Bootstrap package: 
* bootstrap.css
* bootstrap.js
* modernizr.js
* the latest jquery.js

And one data-group class:
* pool_member_status_list


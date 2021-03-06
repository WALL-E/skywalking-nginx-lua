use Test::Nginx::Socket 'no_plan';

use Cwd qw(cwd);
my $pwd = cwd();

repeat_each(1);
no_long_string();
no_shuffle();
no_root_location();
log_level('info');

our $HttpConfig = qq{
    lua_package_path "$pwd/lib/?.lua;;";
    error_log logs/error.log debug;
    resolver 114.114.114.114 8.8.8.8 ipv6=off;
    lua_shared_dict tracing_buffer 100m;
};

run_tests;

__DATA__

=== TEST 1: timestamp
--- http_config eval: $::HttpConfig
--- config
    location /t {
        content_by_lua_block {
            local util = require('skywalking.util')
            local timestamp = util.timestamp()
            local regex = [[^\d+$]]
            local m = ngx.re.match(timestamp, regex)
            if m and tonumber(m[0]) == timestamp then
                ngx.say("done")
            else
                ngx.say("failed to generate timestamp: ", timestamp)
            end
        }
    }
--- request
GET /t
--- response_body
done
--- no_error_log
[error]



=== TEST 2: newID
--- http_config eval: $::HttpConfig
--- config
    location /t {
        content_by_lua_block {
            local util = require('skywalking.util')
            local id = util.newID()
            local regex = [[^[0-9a-f]+\-[0-9a-f]+\-[0-9a-f]+\-[0-9a-f]+\-[0-9a-f]+$]]
            local m = ngx.re.match(id, regex)
            if m then
                ngx.say("done")
                return
            end

            regex = [[^\d+.\d+.\d+$]]
            m = ngx.re.match(id, regex)
            if m then
                ngx.say("done")
            else
                ngx.say("failed to generate id: ", id)
            end
        }
    }
--- request
GET /t
--- response_body
done
--- no_error_log
[error]

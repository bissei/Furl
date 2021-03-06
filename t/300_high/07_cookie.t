use strict;
use warnings;
use utf8;
use Test::More;
use Test::Requires 'HTTP::CookieJar', 'Plack::Request', 'Plack::Loader', 'Plack::Builder', 'Plack::Response';
use Test::TCP;
use Furl;

subtest 'Simple case', sub {
    test_tcp(
        client => sub {
            my $port = shift;
            my $furl = Furl->new(
                cookie_jar => HTTP::CookieJar->new()
            );
            my $url = "http://127.0.0.1:$port";

            subtest 'first time access', sub {
                my $res = $furl->get("${url}/");

                note "Then, response should be 200 OK";
                is $res->status, 200;
                note "And, content should be 'OK 1'";
                is $res->content, 'OK 1';
            };

            subtest 'Second time access', sub {
                my $res = $furl->get("${url}/");

                note "Then, response should be 200 OK";
                is $res->status, 200;
                note "And, content should be 'OK 2'";
                is $res->content, 'OK 2';
            };
        },
        server => \&session_server,
    );
};

subtest '->request(host => ...) style simple interface', sub {
    test_tcp(
        client => sub {
            my $port = shift;
            my $furl = Furl->new(
                cookie_jar => HTTP::CookieJar->new()
            );

            subtest 'first time access', sub {
                my $res = $furl->request(
                    method => 'GET',
                    scheme => 'http',
                    host => '127.0.0.1',
                    port => $port,
                );

                note "Then, response should be 200 OK";
                is $res->status, 200;
                note "And, content should be 'OK 1'";
                is $res->content, 'OK 1';
            };

            subtest 'Second time access', sub {
                my $res = $furl->request(
                    method => 'GET',
                    scheme => 'http',
                    host => '127.0.0.1',
                    port => $port,
                );

                note "Then, response should be 200 OK";
                is $res->status, 200;
                note "And, content should be 'OK 2'";
                is $res->content, 'OK 2';
            };
        },
        server => \&session_server,
    );
};

done_testing;

sub session_server {
    my $port = shift;
    my %SESSION_STORE;
    Plack::Loader->auto( port => $port )->run(builder {
        enable 'ContentLength';

        sub {
            my $env     = shift;
            my $req = Plack::Request->new($env);
            my $session_key = $req->cookies->{session_key} || rand();
            my $cnt = ++$SESSION_STORE{$session_key};
            note "CNT: $cnt";
            my $res = Plack::Response->new(
                200, [], ["OK ${cnt}"]
            );
            $res->cookies->{'session_key'} = $session_key;
            return $res->finalize;
        };
    });
}

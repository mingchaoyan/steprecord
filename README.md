# steprecord
Pure Erlang project for tracing which step the client crashes

## requirements
* Erlang/OTP 
* rebar3

## start
```
rebar3 compile
```

## release
```
rebar3 as prod tar
```

## deploy
```
mkdir steprecord
mv steprecord-0.1.0.tar.gz steprecord
cd steprecord
tar -zxvf steprecord-0.1.0.tar.gz
./bin/steprecord start
```

## report
```
./bin/steprecord remote_console
> steprecord_app:report(imei).
> steprecord_app:report(client_id).
```

## version
[Semantic Versioning 2.0.0](http://semver.org/)

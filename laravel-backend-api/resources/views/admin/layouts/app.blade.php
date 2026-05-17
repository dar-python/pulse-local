<!doctype html>
<html lang="en">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <meta name="csrf-token" content="{{ csrf_token() }}">
    <title>@yield('title', 'PulseLocal Admin')</title>
    <link rel="stylesheet" href="{{ asset('admin/css/dashboard.css') }}">
    @stack('styles')
</head>
<body>
    @yield('body')

    @stack('scripts')
</body>
</html>

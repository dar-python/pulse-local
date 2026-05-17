@extends('admin.layouts.app')

@section('title', 'PulseLocal Admin Login')

@section('body')
    <main class="login-page">
        <section class="login-card" aria-labelledby="admin-login-title">
            <div class="login-header">
                <div class="login-brand">
                    <div class="logo">PL</div>
                    <div class="brand-text">
                        <strong>PulseLocal</strong>
                        <span>Admin Web</span>
                    </div>
                </div>
                <div class="login-copy">
                    <h1 id="admin-login-title">PulseLocal Admin</h1>
                    <p>Sign in with a seeded admin account to open the dashboard.</p>
                </div>
            </div>

            <div class="login-body">
                @if ($errors->any())
                    <div class="error-box">
                        {{ $errors->first() }}
                    </div>
                @endif

                <form method="POST" action="{{ route('admin.login.store') }}">
                    @csrf
                    <div class="field">
                        <label for="username">Username</label>
                        <input id="username" name="username" type="text" value="{{ old('username') }}" autocomplete="username" required autofocus>
                    </div>

                    <div class="field">
                        <label for="password">Password</label>
                        <input id="password" name="password" type="password" autocomplete="current-password" required>
                    </div>

                    <button class="login-submit" type="submit">Sign in</button>
                </form>

                <p class="login-hint">Seeded users: admin and superadmin.</p>
            </div>
        </section>
    </main>
@endsection

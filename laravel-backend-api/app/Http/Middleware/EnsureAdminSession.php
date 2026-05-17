<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Symfony\Component\HttpFoundation\Response;

class EnsureAdminSession
{
    /**
     * @Dashboard: Protects Blade admin routes with the existing session guard and user role.
     */
    public function handle(Request $request, Closure $next): Response
    {
        $user = Auth::user();

        if (! $user) {
            return redirect()->route('admin.login');
        }

        if (! method_exists($user, 'isAdminUser') || ! $user->isAdminUser()) {
            abort(403);
        }

        return $next($request);
    }
}

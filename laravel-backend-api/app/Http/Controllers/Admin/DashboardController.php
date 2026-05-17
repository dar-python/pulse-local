<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Services\AdminDashboardData;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\View\View;

class DashboardController extends Controller
{
    /**
     * @Dashboard: Renders the static first-pass admin dashboard from fake data arrays.
     */
    public function __invoke(Request $request, AdminDashboardData $dashboardData): View
    {
        $allowedSections = [
            'overview',
            'users',
            'partners',
            'operations',
            'financials',
            'analytics',
            'disputes',
            'settings',
        ];
        $section = $request->query('section', 'overview');
        $activeSection = in_array($section, $allowedSections, true) ? $section : 'overview';
        $user = Auth::user();

        return view('admin.dashboard.index', [
            'activeSection' => $activeSection,
            'dashboard' => $dashboardData->toArray(),
            'adminUser' => $user,
            'isSuperAdmin' => $user?->isSuperAdmin() ?? false,
            'roleLabel' => $user?->isSuperAdmin() ? 'Super Admin' : 'Admin',
            'roleDescription' => $user?->isSuperAdmin() ? 'Platform Super Admin' : 'Platform Admin',
            'roleInitials' => $user?->isSuperAdmin() ? 'SA' : 'A',
        ]);
    }
}

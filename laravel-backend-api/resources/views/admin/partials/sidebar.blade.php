@php
    $navItems = [
        ['section' => 'overview', 'label' => 'Overview', 'icon' => 'D'],
        ['section' => 'users', 'label' => 'Users', 'icon' => 'U'],
        ['section' => 'partners', 'label' => 'Partners', 'icon' => 'P'],
        ['section' => 'operations', 'label' => 'Operations', 'icon' => 'O'],
        ['section' => 'financials', 'label' => 'Financials', 'icon' => 'F'],
        ['section' => 'analytics', 'label' => 'Analytics', 'icon' => 'A'],
        ['section' => 'disputes', 'label' => 'Disputes', 'icon' => '!'],
        ['section' => 'settings', 'label' => 'Settings', 'icon' => 'S'],
    ];
@endphp

{{-- @Dashboard: Sidebar links keep the static dashboard visually navigable by section. --}}
<aside class="sidebar">
    <div class="brand">
        <div class="logo">PL</div>
        <div class="brand-text">
            <strong>PulseLocal</strong>
            <span>Admin Web</span>
        </div>
    </div>

    <span class="nav-label">Navigation</span>
    <nav class="nav" id="sideNav" aria-label="Admin sections">
        @foreach ($navItems as $item)
            <a class="{{ $activeSection === $item['section'] ? 'active' : '' }}" href="{{ route('admin.dashboard', ['section' => $item['section']]) }}">
                <span class="nav-ico" aria-hidden="true">{{ $item['icon'] }}</span>
                {{ $item['label'] }}
                @if ($item['section'] === 'settings')
                    <span class="super-only-badge">Super</span>
                @endif
            </a>
        @endforeach
    </nav>

    <div class="sidebar-footer">
        <div class="role-badge-sidebar">
            <div class="avatar">{{ $roleInitials }}</div>
            <div class="info">
                <strong>{{ $adminUser->name }}</strong>
                <span>{{ $roleDescription }}</span>
            </div>
            <span class="role-pill {{ $isSuperAdmin ? 'super' : 'admin' }}">{{ $roleInitials }}</span>
        </div>

        <form method="POST" action="{{ route('admin.logout') }}">
            @csrf
            <button class="logout-btn" type="submit">
                <span class="nav-ico" aria-hidden="true">L</span>
                Logout
            </button>
        </form>
    </div>
</aside>

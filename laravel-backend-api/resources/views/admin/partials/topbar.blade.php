<header class="topbar">
    <div class="topbar-left">
        <p>PulseLocal Admin</p>
        <h1>System Administration Dashboard</h1>
    </div>

    <div class="search-bar">
        <span aria-hidden="true">Search</span>
        <input type="search" placeholder="Search users, partners, orders">
    </div>

    <div class="topbar-right">
        <div class="role-display">
            {{ $roleLabel }}
        </div>

        <button class="notif-btn" id="notifButton" type="button" aria-label="Notifications">
            <span aria-hidden="true">N</span>
            <span class="notif-dot" id="notifDot"></span>
        </button>

        <div class="profile-area">
            <div class="profile-copy">
                <strong>{{ $adminUser->name }}</strong>
                <span>{{ $roleLabel }}</span>
            </div>
            <div class="avatar-lg">{{ $roleInitials }}</div>
        </div>
    </div>
</header>

<div class="notif-tray" id="notifTray">
    <div class="notif-header">
        <strong>Alerts <span class="badge high">3 new</span></strong>
        <button type="button" id="clearNotifications">Clear all</button>
    </div>
    <div class="notif-item">
        <div class="notif-icon urgent">!</div>
        <div class="notif-text"><strong>76 high-risk orders pending review</strong><span>2 min ago - Operations</span></div>
    </div>
    <div class="notif-item">
        <div class="notif-icon warn">W</div>
        <div class="notif-text"><strong>Metro Express Bites - 31 high-risk flags</strong><span>14 min ago - Partners</span></div>
    </div>
    <div class="notif-item">
        <div class="notif-icon info">I</div>
        <div class="notif-text"><strong>DSP-1048 escalated by Mia Collins</strong><span>38 min ago - Disputes</span></div>
    </div>
</div>

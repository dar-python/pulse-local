@extends('admin.layouts.app')

@section('title', 'PulseLocal Admin Dashboard')

@section('body')
    <h2 class="sr-only">PulseLocal Admin Dashboard - system administration overview with role-based access controls</h2>

    <div class="shell">
        @include('admin.partials.sidebar')

        <main class="main">
            @include('admin.partials.topbar')

            <div class="content">
                <section class="metrics" id="overview">
                    @foreach ($dashboard['metrics'] as $metric)
                        @include('admin.partials.metric-card', ['metric' => $metric])
                    @endforeach
                </section>

                <div class="grid2" id="analytics">
                    <div class="panel">
                        <div class="panel-header">
                            <div>
                                <h2>Fulfillment Risk Trend</h2>
                                <p>Weekly risk volume by day</p>
                            </div>
                            <span class="pill">Mon - Sun</span>
                        </div>
                        <div class="chart-bars" id="riskChart"></div>
                    </div>

                    <div class="panel">
                        <div class="panel-header">
                            <div>
                                <h2>Risk Distribution</h2>
                                <p>Checkout-level prediction mix</p>
                            </div>
                        </div>
                        <div class="donut-wrap">
                            <svg class="donut-svg" viewBox="0 0 140 140" role="img" aria-label="Risk distribution">
                                <circle cx="70" cy="70" r="52" fill="none" stroke="#1a7a2e" stroke-width="22" stroke-dasharray="157 327" stroke-dashoffset="0"/>
                                <circle cx="70" cy="70" r="52" fill="none" stroke="#fca311" stroke-width="22" stroke-dasharray="82 327" stroke-dashoffset="-157"/>
                                <circle cx="70" cy="70" r="52" fill="none" stroke="#c0392b" stroke-width="22" stroke-dasharray="59 327" stroke-dashoffset="-239"/>
                                <circle cx="70" cy="70" r="52" fill="none" stroke="#b0bec8" stroke-width="22" stroke-dasharray="29 327" stroke-dashoffset="-298"/>
                                <text x="70" y="67" text-anchor="middle" font-size="13" font-weight="800" fill="#14213d">Risk</text>
                                <text x="70" y="81" text-anchor="middle" font-size="10" fill="#415a77">Mix</text>
                            </svg>
                            <div class="legend">
                                <div class="leg-row"><span class="leg-left"><span class="leg-dot" style="background:#1a7a2e"></span><span class="badge low">Low</span></span><span>48%</span></div>
                                <div class="leg-row"><span class="leg-left"><span class="leg-dot" style="background:#fca311"></span><span class="badge medium">Medium</span></span><span>25%</span></div>
                                <div class="leg-row"><span class="leg-left"><span class="leg-dot" style="background:#c0392b"></span><span class="badge high">High</span></span><span>18%</span></div>
                                <div class="leg-row"><span class="leg-left"><span class="leg-dot" style="background:#b0bec8"></span><span class="badge unknown">Unknown</span></span><span>9%</span></div>
                            </div>
                        </div>
                    </div>
                </div>

                <div class="grid2">
                    <div class="panel" id="operations">
                        <div class="panel-header">
                            <div>
                                <h2>Recent High-Risk Orders</h2>
                                <p>Orders flagged for review</p>
                            </div>
                        </div>
                        <div class="table-wrap">
                            <table>
                                <thead>
                                    <tr>
                                        <th>Order</th>
                                        <th>Customer</th>
                                        <th>Merchant</th>
                                        <th>Score</th>
                                        <th>Risk</th>
                                        <th>Status</th>
                                        <th>Actions</th>
                                    </tr>
                                </thead>
                                <tbody>
                                    @foreach ($dashboard['recentHighRiskOrders'] as $order)
                                        <tr>
                                            <td>{{ $order['id'] }}</td>
                                            <td>{{ $order['customer'] }}</td>
                                            <td>{{ $order['merchant'] }}</td>
                                            <td><strong>{{ $order['score'] }}</strong></td>
                                            <td><span class="badge {{ $order['risk'] }}">{{ ucfirst($order['risk']) }}</span></td>
                                            <td><span class="badge {{ $order['status'] }}">{{ ucfirst($order['status']) }}</span></td>
                                            <td>
                                                <button class="action-btn review" type="button" data-toast="Reviewing {{ $order['id'] }}">Review</button>
                                                <button class="action-btn resolve" type="button" data-toast="{{ $order['id'] }} resolved" @disabled(! $isSuperAdmin)>Resolve</button>
                                            </td>
                                        </tr>
                                    @endforeach
                                </tbody>
                            </table>
                        </div>
                    </div>

                    <div class="panel" id="partners">
                        <div class="panel-header">
                            <div>
                                <h2>Partner Performance</h2>
                                <p>Merchant fulfillment health</p>
                            </div>
                        </div>
                        <div class="table-wrap">
                            <table>
                                <thead>
                                    <tr>
                                        <th>Merchant</th>
                                        <th>Prep</th>
                                        <th>Success</th>
                                        <th>Risk</th>
                                        <th>Status</th>
                                        <th>Actions</th>
                                    </tr>
                                </thead>
                                <tbody>
                                    @foreach ($dashboard['partnerPerformance'] as $partner)
                                        <tr>
                                            <td>{{ $partner['name'] }}</td>
                                            <td>{{ $partner['prep'] }}</td>
                                            <td>{{ $partner['success'] }}</td>
                                            <td>{{ $partner['risk'] }}</td>
                                            <td><span class="badge {{ $partner['status'] }}">{{ ucfirst($partner['status']) }}</span></td>
                                            <td>
                                                <button class="action-btn review" type="button" data-toast="Viewing {{ $partner['name'] }}">View</button>
                                                <button class="action-btn suspend" type="button" data-toast="{{ $partner['name'] }} actioned" @disabled(! $isSuperAdmin)>Suspend</button>
                                            </td>
                                        </tr>
                                    @endforeach
                                </tbody>
                            </table>
                        </div>
                    </div>
                </div>

                <div class="grid2-equal">
                    <div class="panel" id="disputes">
                        <div class="panel-header">
                            <div>
                                <h2>Dispute Queue</h2>
                                <p>Cases awaiting action</p>
                            </div>
                        </div>
                        <div class="table-wrap">
                            <table>
                                <thead>
                                    <tr>
                                        <th>ID</th>
                                        <th>User</th>
                                        <th>Order</th>
                                        <th>Reason</th>
                                        <th>Status</th>
                                        <th>Actions</th>
                                    </tr>
                                </thead>
                                <tbody>
                                    @foreach ($dashboard['disputeQueue'] as $dispute)
                                        <tr>
                                            <td>{{ $dispute['id'] }}</td>
                                            <td>{{ $dispute['user'] }}</td>
                                            <td>{{ $dispute['order'] }}</td>
                                            <td>{{ $dispute['reason'] }}</td>
                                            <td><span class="badge {{ $dispute['status'] }}">{{ ucfirst($dispute['status']) }}</span></td>
                                            <td>
                                                <button class="action-btn review" type="button" data-toast="Escalating {{ $dispute['id'] }}">Escalate</button>
                                                <button class="action-btn resolve" type="button" data-toast="{{ $dispute['id'] }} resolved" @disabled(! $isSuperAdmin)>Resolve</button>
                                            </td>
                                        </tr>
                                    @endforeach
                                </tbody>
                            </table>
                        </div>
                    </div>

                    <div class="panel">
                        <div class="panel-header">
                            <div>
                                <h2>Operational Snapshot</h2>
                                <p>Platform operations at a glance</p>
                            </div>
                        </div>
                        <div class="snap-grid">
                            @foreach ($dashboard['operationalSnapshot'] as $snapshot)
                                <div class="snap-card {{ $snapshot['tone'] }}">
                                    <strong>{{ $snapshot['label'] }}</strong>
                                    <span>{{ $snapshot['value'] }}</span>
                                    <p>{{ $snapshot['note'] }}</p>
                                </div>
                            @endforeach
                        </div>
                    </div>
                </div>

                <div class="panel" id="financials">
                    <div class="panel-header">
                        <div>
                            <h2>Financial Summary</h2>
                            <p>Daily platform totals</p>
                        </div>
                        <span class="pill">Today</span>
                    </div>
                    <div class="finance-grid">
                        @foreach ($dashboard['financialSummary'] as $finance)
                            <div class="fin-card {{ $finance['tone'] }}">
                                <strong>{{ $finance['label'] }}</strong>
                                <span>{{ $finance['value'] }}</span>
                                <p>{{ $finance['note'] }}</p>
                            </div>
                        @endforeach
                    </div>
                </div>

                <div class="panel" id="settings">
                    <div class="panel-header">
                        <div>
                            <h2>System Settings <span class="super-only-badge">Super Admin only</span></h2>
                            <p>Platform configuration controls</p>
                        </div>
                    </div>

                    @unless ($isSuperAdmin)
                        <div class="lock-overlay">These controls require Super Admin access.</div>
                    @endunless

                    <div class="settings-grid settings-controls {{ $isSuperAdmin ? '' : 'locked' }}">
                        <div class="setting-card">
                            <strong>Risk Threshold</strong>
                            <label for="riskSlider">Review trigger score</label>
                            <div class="slider-row">
                                <input id="riskSlider" type="range" min="0.5" max="0.99" step="0.01" value="0.75" @disabled(! $isSuperAdmin)>
                                <span class="slider-val" id="riskVal">0.75</span>
                            </div>
                        </div>

                        <div class="setting-card">
                            <strong>Fallback Mode</strong>
                            <label>Unknown-risk handling</label>
                            <div class="toggle-row">
                                <span class="setting-text" id="fallbackLabel">Ready (off)</span>
                                <button class="toggle" id="fallbackToggle" type="button" aria-label="Toggle fallback mode" @disabled(! $isSuperAdmin)></button>
                            </div>
                        </div>

                        <div class="setting-card">
                            <strong>System Status</strong>
                            <label>Override status flag</label>
                            <div class="toggle-row">
                                <span class="setting-text">Stable</span>
                                <button class="save-btn" type="button" data-toast="Status saved" @disabled(! $isSuperAdmin)>Save</button>
                            </div>
                        </div>

                        <div class="setting-card">
                            <strong>Admin Accounts</strong>
                            <label>Manage admin users</label>
                            <button class="save-btn" type="button" data-toast="Admin management opened" @disabled(! $isSuperAdmin)>Manage Admins</button>
                        </div>

                        <div class="setting-card">
                            <strong>COD Risk Boost</strong>
                            <label for="codSlider">Extra weight for cash orders</label>
                            <div class="slider-row">
                                <input id="codSlider" type="range" min="0" max="0.3" step="0.01" value="0.12" @disabled(! $isSuperAdmin)>
                                <span class="slider-val" id="codVal">+0.12</span>
                            </div>
                        </div>

                        <div class="setting-card">
                            <strong>Save Config</strong>
                            <label>Apply all threshold changes</label>
                            <button class="save-btn" type="button" data-toast="Configuration saved" @disabled(! $isSuperAdmin)>Save All Settings</button>
                        </div>
                    </div>
                </div>
            </div>
        </main>
    </div>

    <div class="toast" id="toast"><span id="toastMsg"></span></div>
@endsection

@push('scripts')
    <script>
        window.PulseLocalDashboard = {
            chartBars: @json($dashboard['chartBars'])
        };
    </script>
    <script src="{{ asset('admin/js/dashboard.js') }}" defer></script>
@endpush

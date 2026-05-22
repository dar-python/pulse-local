<!DOCTYPE html>
<html lang="{{ str_replace('_', '-', app()->getLocale()) }}">
    <head>
        <meta charset="utf-8">
        <meta name="viewport" content="width=device-width, initial-scale=1">
        <title>FoodPulse | Checkout Fulfillment Risk Prediction</title>
        <link rel="stylesheet" href="/landing/foodpulse.css">
    </head>
    <body>
        <header class="site-header">
            <nav class="shell nav-bar" aria-label="FoodPulse sections">
                <a class="brand" href="#overview" aria-label="FoodPulse overview">
                    <img class="brand-logo" src="/landing/images/logoeagle.png" alt="FoodPulse logo">
                    <span>
                        <strong>FoodPulse</strong>
                        <small>Checkout Risk Prediction</small>
                    </span>
                </a>

                <div class="nav-links">
                    <a href="#architecture">Architecture</a>
                    <a href="#weather">Weather</a>
                    <a href="#model">Model</a>
                    <a href="#deployment">Deployment</a>
                    <a href="#api">API</a>
                </div>
            </nav>
        </header>

        <main>
            <section id="overview" class="hero band">
                <div class="shell hero-grid">
                    <div class="hero-copy">
                        <p class="eyebrow">Academic research and deployed system prototype</p>
                        <div class="hero-title">
                            <img class="hero-logo" src="/landing/images/logoeagle.png" alt="FoodPulse logo">
                            <h1>FoodPulse</h1>
                        </div>
                        <p class="hero-lead">Checkout-level fulfillment risk prediction for quick-commerce.</p>
                        <p class="hero-body">
                            FoodPulse combines a Flutter mobile app, a Laravel API, real-time checkout enrichment,
                            and an internal FastAPI model service so customers see fulfillment risk before confirming
                            an order.
                        </p>

                        <div class="hero-actions">
                            <a class="button button-primary" href="#architecture">View system flow</a>
                            <a class="button button-secondary" href="/api/health">Check API health</a>
                        </div>
                    </div>

                    <aside class="risk-preview" aria-label="Example FoodPulse risk result">
                        <div class="preview-topline">
                            <span>checkout_prediction</span>
                            <strong>Live path</strong>
                        </div>

                        <div class="score-dial">
                            <span>0.68</span>
                            <small>Risk score</small>
                        </div>

                        <div class="preview-grid">
                            <div>
                                <small>Weather source</small>
                                <strong>Laravel enriched</strong>
                            </div>
                            <div>
                                <small>Risk level</small>
                                <strong class="risk-medium">Medium</strong>
                            </div>
                            <div>
                                <small>Mobile client</small>
                                <strong>Flutter</strong>
                            </div>
                            <div>
                                <small>Public API</small>
                                <strong>Laravel only</strong>
                            </div>
                        </div>
                    </aside>
                </div>
            </section>

            <section class="band overview-band">
                <div class="shell section-stack">
                    <div class="section-head">
                        <p class="eyebrow">Project scope</p>
                        <h2>Risk-aware checkout, not a disconnected demo.</h2>
                        <p>
                            The deployed flow keeps public traffic on Laravel while using prediction output to explain
                            delivery risk, ETA changes, and advisories in the mobile checkout experience.
                        </p>
                    </div>

                    <div class="card-grid card-grid-four">
                        <article class="info-card">
                            <span>01</span>
                            <h3>Checkout Context</h3>
                            <p>Flutter sends order, address, payment, and optional delivery location context to Laravel.</p>
                        </article>
                        <article class="info-card">
                            <span>02</span>
                            <h3>Laravel Enrichment</h3>
                            <p>Laravel validates the request, resolves current weather, and normalizes prediction inputs.</p>
                        </article>
                        <article class="info-card">
                            <span>03</span>
                            <h3>Internal Prediction</h3>
                            <p>The private FastAPI ML service scores the deployed Logistic Regression model.</p>
                        </article>
                        <article class="info-card">
                            <span>04</span>
                            <h3>Checkout Advisory</h3>
                            <p>Laravel returns a risk score, risk level, ETA guidance, and customer-facing advisory.</p>
                        </article>
                    </div>
                </div>
            </section>

            <section id="architecture" class="band architecture-band">
                <div class="shell section-stack">
                    <div class="section-head">
                        <p class="eyebrow">Architecture</p>
                        <h2>Public mobile traffic stays on the Laravel boundary.</h2>
                        <p>
                            Flutter calls Laravel only. Laravel validates and normalizes checkout payloads, resolves
                            real-time weather, and calls the internal ML service. The ML service and MySQL are not
                            publicly exposed.
                        </p>
                    </div>

                    <div class="flow-row" aria-label="FoodPulse checkout prediction architecture">
                        <div class="flow-node">Flutter Mobile App</div>
                        <span class="flow-arrow" aria-hidden="true">-&gt;</span>
                        <div class="flow-node flow-node-accent">Laravel API</div>
                        <span class="flow-arrow" aria-hidden="true">-&gt;</span>
                        <div class="flow-node">Real-Time Weather Enrichment</div>
                        <span class="flow-arrow" aria-hidden="true">-&gt;</span>
                        <div class="flow-node">Internal FastAPI ML Service</div>
                        <span class="flow-arrow" aria-hidden="true">-&gt;</span>
                        <div class="flow-node">Deployed Logistic Regression Model</div>
                        <span class="flow-arrow" aria-hidden="true">-&gt;</span>
                        <div class="flow-node flow-node-result">Risk Score + Advisory</div>
                    </div>

                    <div class="architecture-notes">
                        <article class="note-panel">
                            <p class="eyebrow">Persistence branch</p>
                            <h3>Laravel API -&gt; MySQL Database</h3>
                            <p>Application data stays behind the API and inside the container network.</p>
                        </article>
                        <article class="note-panel">
                            <p class="eyebrow">Public edge</p>
                            <h3>DuckDNS + Let's Encrypt</h3>
                            <p>Public traffic reaches FoodPulse over HTTPS before Laravel handles API work.</p>
                        </article>
                    </div>
                </div>
            </section>

            <section id="weather" class="band weather-band">
                <div class="shell weather-layout">
                    <div class="section-head">
                        <p class="eyebrow">Checkout enrichment</p>
                        <h2>Real-Time Weather Enrichment</h2>
                        <p>
                            FoodPulse does not rely only on static weather labels. The Laravel API resolves current
                            weather conditions during checkout and includes them in the prediction payload used for
                            fulfillment-risk scoring.
                        </p>
                    </div>

                    <article class="weather-card">
                        <h3>Laravel owns the weather lookup.</h3>
                        <p>During checkout, Laravel enriches the request with current weather data from the configured weather API before forwarding normalized features to the ML service.</p>
                        <ul>
                            <li>Flutter may send optional <code>delivery_latitude</code> and <code>delivery_longitude</code>.</li>
                            <li>Laravel resolves the current weather condition during checkout.</li>
                            <li>Laravel sends normalized checkout, weather, traffic, and delivery features internally.</li>
                            <li>The weather provider secret and private ML service URL stay server-side.</li>
                        </ul>
                    </article>
                </div>
            </section>

            <section id="model" class="band model-band">
                <div class="shell section-stack">
                    <div class="section-head">
                        <p class="eyebrow">Current deployed model</p>
                        <h2>Calibrated evaluation metrics.</h2>
                        <p>
                            These public showcase values are defined once in Laravel and were verified against
                            <code>ml-service/app/models/pulselocal_model_metadata.json</code> for the current deployed
                            Logistic Regression artifact.
                        </p>
                    </div>

                    <div class="metric-grid">
                        @foreach ($landingMetrics as $metric)
                            <article class="metric-card">
                                <strong>{{ $metric['value'] }}</strong>
                                <span>{{ $metric['label'] }}</span>
                                <div class="metric-track" aria-hidden="true">
                                    <i style="width: {{ $metric['bar'] }}%"></i>
                                </div>
                            </article>
                        @endforeach
                    </div>

                    <div class="cross-validation">
                        @foreach ($landingCrossValidation as $metric)
                            <article class="stat-pill">
                                <span>{{ $metric['label'] }}</span>
                                <strong>{{ $metric['value'] }}</strong>
                            </article>
                        @endforeach
                    </div>
                </div>
            </section>

            <section class="band checkout-band">
                <div class="shell section-stack">
                    <div class="section-head">
                        <p class="eyebrow">Checkout flow</p>
                        <h2>From cart review to a risk-aware response.</h2>
                    </div>

                    <div class="step-grid">
                        <article class="step-card">
                            <span>01</span>
                            <h3>Mobile checkout</h3>
                            <p>Flutter sends the validated customer checkout context to Laravel over HTTPS.</p>
                        </article>
                        <article class="step-card">
                            <span>02</span>
                            <h3>Weather + features</h3>
                            <p>Laravel resolves current weather and builds normalized model-ready features.</p>
                        </article>
                        <article class="step-card">
                            <span>03</span>
                            <h3>Private scoring</h3>
                            <p>The internal FastAPI service scores the deployed model artifact.</p>
                        </article>
                        <article class="step-card">
                            <span>04</span>
                            <h3>Risk display</h3>
                            <p>Laravel returns the prediction and advisory that Flutter shows before confirmation.</p>
                        </article>
                    </div>
                </div>
            </section>

            <section id="deployment" class="band deployment-band">
                <div class="shell section-stack">
                    <div class="section-head">
                        <p class="eyebrow">Deployment</p>
                        <h2>Containerized services with a protected internal network.</h2>
                        <p>
                            Docker and GHCR carry the production images, while DuckDNS, Certbot, and Nginx support the
                            public HTTPS edge without exposing FastAPI or MySQL directly.
                        </p>
                    </div>

                    <div class="card-grid card-grid-four">
                        <article class="info-card">
                            <span>AWS</span>
                            <h3>EC2 host</h3>
                            <p>FoodPulse services run on the production server as a Dockerized stack.</p>
                        </article>
                        <article class="info-card">
                            <span>GHCR</span>
                            <h3>Image delivery</h3>
                            <p>GitHub workflows publish service images for deployment.</p>
                        </article>
                        <article class="info-card">
                            <span>HTTPS</span>
                            <h3>Public edge</h3>
                            <p>DuckDNS, Let's Encrypt, Certbot, and Nginx secure public traffic.</p>
                        </article>
                        <article class="info-card">
                            <span>LAN</span>
                            <h3>Private services</h3>
                            <p>Laravel calls FastAPI internally and MySQL remains off the public edge.</p>
                        </article>
                    </div>
                </div>
            </section>

            <section id="api" class="band api-band">
                <div class="shell api-layout">
                    <div class="section-head">
                        <p class="eyebrow">Public API</p>
                        <h2>Laravel endpoints exposed to clients.</h2>
                        <p>
                            The ML service remains internal. Public clients use the deployed Laravel base URL.
                        </p>
                    </div>

                    <div class="api-panel">
                        <div class="base-url">
                            <span>Base URL</span>
                            <code>https://foodpulse-zuniega-docil.duckdns.org</code>
                        </div>

                        <article class="endpoint">
                            <strong class="method method-get">GET</strong>
                            <div>
                                <code>/api/health</code>
                                <p>Returns Laravel API health JSON.</p>
                            </div>
                        </article>

                        <article class="endpoint">
                            <strong class="method method-post">POST</strong>
                            <div>
                                <code>/api/checkout/risk</code>
                                <p>
                                    Accepts checkout context from Flutter. Laravel enriches the payload and returns the
                                    risk score, risk level, ETA guidance, and advisory.
                                </p>
                                <div class="field-row" aria-label="Checkout request fields">
                                    <code>restaurant_slug</code>
                                    <code>items</code>
                                    <code>delivery_address</code>
                                    <code>payment_method</code>
                                    <code>delivery_latitude</code>
                                    <code>delivery_longitude</code>
                                </div>
                            </div>
                        </article>
                    </div>
                </div>
            </section>
        </main>

        <footer class="site-footer">
            <div class="shell footer-row">
                <span class="brand-mark" aria-hidden="true">FP</span>
                <div>
                    <strong>FoodPulse | Zuniega Docil © 2026</strong>
                    <p>Built with Flutter, Laravel, FastAPI, MySQL, Docker, and Logistic Regression.</p>
                </div>
            </div>
        </footer>
    </body>
</html>

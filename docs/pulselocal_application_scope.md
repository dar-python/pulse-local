# PulseLocal Application Scope

## Application Name

**PulseLocal**

## Application Type

PulseLocal is a **hyper-local mobile e-commerce application** with a checkout-level fulfillment-risk prediction feature. The application is designed to support same-day or within-the-hour commerce by helping customers, merchants, and the platform identify whether an order may experience delayed or failed fulfillment before the order is confirmed.

---

## Application Purpose

The purpose of the application is to provide a **risk-aware checkout experience**. Instead of allowing users to place orders without visibility into fulfillment uncertainty, the system calculates a **Fulfillment Risk Score** based on operational factors such as rider availability, merchant preparation time, traffic conditions, weather, delivery distance, address complexity, payment method, and historical fulfillment outcomes.

The application does not only display products and process checkout. Its key value is that it uses prediction to support better checkout decisions.

---

## Core Application Flow

```txt
Customer opens Flutter mobile app
        ↓
Customer enters or confirms checkout details
        ↓
Flutter sends checkout data to Laravel API
        ↓
Laravel forwards risk-related features to Python ML service
        ↓
Python service returns fulfillment-risk prediction
        ↓
Laravel returns risk score and recommendation to Flutter
        ↓
Flutter displays checkout advisory and recommended action
```

---

## Target Users

### 1. Customer

The customer uses the mobile application to browse or prepare an order, enter checkout details, and view the fulfillment-risk advisory before confirming the order.

### 2. Merchant

The merchant receives risk-related alerts when an order is predicted to have high fulfillment risk, especially when stock readiness or preparation delay may affect the order.

### 3. Platform Operator / Administrator

The platform operator may review system activity, validate risk behavior, and monitor whether the application is functioning correctly.

> Note: For early development, the customer checkout flow is the primary priority. Merchant and administrator features may be implemented in later iterations depending on project scope and time.

---

## In-Scope Application Features

## 1. Customer Mobile Application

The Flutter mobile app includes the customer-facing interface.

### Included Features

- Mobile checkout screen
- Checkout input form
- Fulfillment-risk calculation trigger
- Loading state while the system calculates risk
- Risk score display
- Risk level display
- Risk recommendation display
- Color-coded risk status:
  - Low = Green
  - Medium = Yellow/Amber
  - High = Red
  - Unknown/Fallback = Gray
- Risk advisory message before checkout confirmation
- Adjusted estimated delivery time display when risk is high
- Payment recommendation display when appropriate
- User-readable error message when the system cannot complete the prediction request

### Customer-Side Purpose

The customer side helps users understand whether the order may be delayed, whether preparation may take longer, or whether additional confirmation is recommended before proceeding.

---

## 2. Checkout Risk Prediction

The main intelligent feature of the application is checkout-level fulfillment-risk prediction.

### Included Prediction Inputs

The application may use the following features:

- Rider-to-order ratio
- Merchant preparation time
- Traffic corridor intensity
- Delivery distance
- Address complexity
- Weather category
- Payment method
- Order timestamp
- Item category
- Rider availability
- Customer location
- Historical fulfillment outcome

### Prediction Output

The system returns:

- Fulfillment risk score
- Risk level
- Recommendation
- Response source

Example output:

```json
{
  "risk_score": 0.72,
  "risk_level": "High",
  "recommendation": "High fulfillment risk. Adjust ETA and notify merchant.",
  "source": "ml-service"
}
```

---

## 3. Laravel Backend API

The Laravel backend serves as the main orchestration layer of the application.

### Included Features

- API endpoint for checkout risk requests
- Request validation
- Data normalization before forwarding to the ML service
- Communication with the Python prediction microservice
- Response formatting for the Flutter frontend
- Timeout handling
- Fallback response when the ML service is unavailable
- Centralized business logic for checkout-risk handling

### Backend Responsibility

Laravel receives checkout data from Flutter, sends the relevant features to the Python service, receives the prediction response, and returns a clean result to the mobile app.

Flutter must not communicate directly with the Python ML service.

---

## 4. Python Prediction Microservice

The Python service handles the machine learning prediction component.

### Included Features

- REST prediction endpoint
- Logistic Regression model integration
- Model loading through serialized file format
- Risk score generation
- Risk level classification
- Recommendation generation
- Lightweight API communication with Laravel

### Model Scope

The model is designed to predict whether an incoming order is at risk of delayed or failed fulfillment.

### Risk Levels

| Risk Score Range | Risk Level |
|---|---|
| 0.00 - 0.39 | Low |
| 0.40 - 0.69 | Medium |
| 0.70 - 1.00 | High |

---

## 5. Merchant Alert Support

When the system detects a high fulfillment-risk score, the application may notify or alert the merchant to verify fulfillment readiness.

### Included Alert Conditions

- High predicted fulfillment risk
- Long merchant preparation time
- Possible stock readiness issue
- High rider demand
- Severe weather or traffic condition

### Included Merchant Actions

- Verify stock availability
- Confirm preparation readiness
- Review order feasibility
- Prepare earlier for high-risk orders

> Merchant-side functionality may begin as a simple alert or status message before becoming a full merchant dashboard.

---

## 6. Risk-Based Checkout Interventions

The application includes checkout-level actions triggered by the fulfillment-risk score.

### Included Interventions

| Risk Level | Application Behavior |
|---|---|
| Low | Proceed with normal checkout |
| Medium | Show mild advisory and realistic ETA |
| High | Show risk warning, adjust ETA, recommend confirmation, alert merchant |
| Unknown | Allow checkout with fallback advisory |

### Purpose

The application does not block checkout by default. It provides decision-support information so users and merchants can act before fulfillment failure happens.

---

## 7. Testing and Validation Features

The application includes testing and validation activities to confirm that the system works correctly.

### Included Testing

- Functional testing
- API testing
- Integration testing
- ML service testing
- Fallback behavior testing
- User-level validation
- Risk display validation

### Validation Focus

The system should be tested to confirm that:

- Checkout data is sent correctly
- Laravel receives and validates the request
- Laravel calls the Python service correctly
- Python returns a valid prediction
- Laravel handles ML service failure gracefully
- Flutter displays the correct risk output
- Users can understand the risk advisory

---

# Out-of-Scope Application Features

The following features are not part of the main application scope unless added in future development.

| Feature | Reason |
|---|---|
| Full payment gateway integration | The study focuses on risk prediction, not payment settlement |
| Real-time rider dispatching | Requires logistics operations beyond checkout prediction |
| Live GPS rider tracking | Outside the fulfillment-risk scoring scope |
| Automated route optimization | Requires mapping, routing, and traffic APIs beyond the study scope |
| Warehouse management | Not part of the hyper-local checkout prediction feature |
| Full inventory management system | Only stock readiness may be considered for risk prediction |
| Refund automation | Post-failure compensation is outside the prevention-focused design |
| Voucher or loyalty system | Not required for fulfillment-risk prediction |
| Large-scale marketplace management | The focus is risk-aware quick-commerce checkout |
| Multi-branch enterprise logistics | Too broad for the proposed application scope |
| Deep learning model deployment | Logistic Regression is the selected model for interpretability |
| Advanced ML operations dashboard | Not required for core application delivery |
| Nationwide commercial deployment | The system is intended for pilot or localized use first |

---

# Application Modules

## 1. Mobile Frontend Module

**Technology:** Flutter

### Responsibilities

- Render checkout interface
- Accept checkout-related input
- Send requests to Laravel API
- Display risk score and recommendation
- Show loading, success, fallback, and error states

---

## 2. Backend API Module

**Technology:** Laravel

### Responsibilities

- Receive requests from Flutter
- Validate checkout data
- Forward prediction features to Python
- Apply fallback behavior when prediction service fails
- Return standardized API response to Flutter

---

## 3. Prediction Service Module

**Technology:** Python with Flask or FastAPI

### Responsibilities

- Load the serialized Logistic Regression model
- Accept prediction features
- Compute fulfillment-risk probability
- Classify risk level
- Return risk result to Laravel

---

## 4. Data Processing and Model Training Module

**Technology:** Python, pandas, scikit-learn, joblib

### Responsibilities

- Select relevant historical data
- Clean incomplete and inconsistent records
- Engineer features
- Train Logistic Regression model
- Evaluate model using standard classification metrics
- Serialize trained model for deployment

---

# Application Boundaries

## The Application Will Do

- Predict fulfillment risk before order confirmation
- Support checkout-level decision-making
- Display risk score and recommendation
- Help customers understand possible delay or failure risk
- Help merchants verify readiness for risky orders
- Use Laravel as the backend orchestration layer
- Use Python for ML prediction
- Use Flutter for the mobile interface

## The Application Will Not Do

- Guarantee delivery success
- Replace human logistics decisions
- Automatically assign riders
- Automatically reroute deliveries
- Manage full inventory operations
- Process actual financial settlement
- Solve all last-mile delivery failures
- Function as a complete Grab/Foodpanda/Shopee clone

---

# Data Scope

The application may use historical and operational data related to quick-commerce fulfillment.

## Included Data

- Order timestamp
- Item category
- Merchant preparation time
- Rider availability
- Rider-to-order ratio
- Delivery distance
- Traffic-related condition
- Weather category
- Payment method
- Customer location
- Address complexity
- Past fulfillment outcome

## Excluded Data

- Sensitive financial account details
- Full payment card data
- Private rider personal data beyond operational availability
- Unrelated customer demographic profiling
- Social media behavior
- Non-commerce personal information

---

# Security and Privacy Scope

The application should apply basic security and privacy controls.

## Included Controls

- API request validation
- Environment-based service URLs
- No hardcoded secrets in source code
- Backend-controlled ML service access
- Basic error handling
- Minimal data collection

## Not Included in Initial Scope

- Enterprise-grade fraud detection
- Advanced identity verification
- Full PCI-DSS payment processing
- Complex role-based access control
- Automated threat monitoring

---

# Deployment Scope

The system may initially be deployed in a local, test, or pilot environment.

## Included

- Local development setup
- API testing
- Mobile app testing
- Service-to-service integration
- Pilot-ready architecture

## Not Included

- Full production scaling
- Load-balanced ML infrastructure
- Cloud-native Kubernetes deployment
- Multi-region availability
- High-availability disaster recovery

---

# Summary of Application Scope

PulseLocal is scoped as a **risk-aware hyper-local checkout application**. Its main function is to predict whether a quick-commerce order may experience fulfillment delay or failure and to present that prediction to the customer and merchant before order confirmation.

The application is not scoped as a full logistics platform, a complete marketplace, a payment processing system, or a route optimization engine. Its strongest contribution is the integration of mobile commerce, backend orchestration, and machine learning-based fulfillment-risk prediction into a working checkout flow.

---

# Final Scope Statement

The scope of the PulseLocal application is to provide a mobile checkout system that uses a Logistic Regression-based prediction service to calculate fulfillment risk in real time. The application will allow customers to submit checkout details, receive a fulfillment-risk score, view risk-based recommendations, and support merchant readiness checks when high-risk conditions are detected. The system will be implemented using Flutter for the mobile frontend, Laravel for backend orchestration, and Python for data processing and prediction. The application will be limited to checkout-level risk prediction and intervention, excluding full logistics automation, real-time rider dispatching, payment settlement, and enterprise-scale marketplace operations.

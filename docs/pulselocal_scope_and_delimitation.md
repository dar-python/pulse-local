# Scope and Delimitation of the Study

## Study Title

**PulseLocal: A Hyper-Local Mobile E-Commerce Application for Predicting Same-Day Fulfillment Risk in Quick Commerce**

---

## Scope of the Study

This study focuses on the design and development of **PulseLocal**, a hyper-local mobile e-commerce application that predicts same-day fulfillment risk during checkout in a quick-commerce environment. The study is centered on helping users, merchants, and platform operators identify whether an order has a high probability of delayed or failed fulfillment before the order is confirmed.

The primary scope of the study includes the development of a **Fulfillment Risk Score** using a Logistic Regression model. The model will analyze selected operational variables that may influence order fulfillment performance, including rider-to-order ratio, merchant preparation time, traffic corridor intensity, delivery distance, address complexity, weather category, payment method, and historical fulfillment outcomes. These variables will be used to estimate whether an incoming order is likely to experience fulfillment risk.

The study will follow the **Knowledge Discovery in Databases (KDD)** process for the data science component. This includes data selection, preprocessing, transformation, data mining, and evaluation. Python will be used for the analytical workflow, with pandas for data preparation and feature engineering, scikit-learn for Logistic Regression model development and evaluation, and joblib for model serialization.

The software development component of the study will follow the **Software Development Life Cycle (SDLC)**. The system will consist of a Flutter-based mobile frontend, a Laravel backend API, and a lightweight Python prediction microservice using Flask or FastAPI. The Laravel backend will act as the orchestration layer by receiving checkout details from the mobile application, forwarding relevant features to the Python prediction service, and returning the computed risk score and recommendation to the Flutter checkout interface.

The functional scope of the application includes a checkout process where the system computes and displays fulfillment risk before order confirmation. When the computed risk is high, the application may adjust the estimated delivery time, show a risk advisory notice to the customer, recommend prepayment confirmation when appropriate, and alert the merchant to verify stock and fulfillment readiness. These interventions are intended to support risk-aware checkout decisions and reduce fulfillment uncertainty.

The model will be evaluated using standard classification performance metrics, including accuracy, precision, recall, F1-score, confusion matrix, and AUC-ROC. The study targets a minimum AUC-ROC of 0.75 to indicate acceptable classification performance. The system will also undergo functional testing, integration testing, and user-level validation to determine whether the prediction and intervention features operate correctly and are understandable to users.

The study is intended for use in an urban or semi-urban Philippine quick-commerce context where customers expect same-day or within-the-hour delivery. It is specifically focused on fulfillment-risk prediction and checkout-level intervention rather than complete logistics automation.

---

## Delimitation of the Study

This study is limited to the prediction of fulfillment risk during the checkout stage of a hyper-local mobile e-commerce transaction. It does not attempt to optimize the entire delivery network, assign riders automatically, manage warehouse inventory, or replace existing logistics management systems.

The study will only use selected operational variables that are observable and available within the participating e-commerce or delivery environment. These include order-related, merchant-related, rider-related, traffic-related, weather-related, payment-related, and location-related features. Variables outside the available data sources will not be included in the model.

The predictive model will use Logistic Regression because it is computationally efficient, interpretable, and appropriate for binary classification. The study will not compare Logistic Regression extensively against more complex models such as Random Forest, Gradient Boosting, Neural Networks, or Deep Learning architectures unless future research extends the system.

The application will focus on generating a fulfillment-risk score and triggering checkout-level recommendations. It will not include full-scale financial transaction processing, real-time rider dispatching, automated route optimization, advanced inventory forecasting, or large-scale enterprise logistics management.

The system implementation will be limited to the proposed technology stack: Flutter for the mobile frontend, Laravel for the backend API, and Python for the model pipeline and prediction microservice. The Laravel backend will serve as the main orchestration layer, while the Python service will only handle prediction-related logic.

The study will be evaluated through functional testing, integration testing, model performance evaluation, and user-level validation. It will not conduct long-term commercial deployment analysis, large-scale market adoption testing, or nationwide logistics performance measurement.

---

## Limitations of the Study

This study is subject to several limitations.

First, the accuracy of the Logistic Regression model depends heavily on the availability, quality, and completeness of historical quick-commerce data. Missing rider information, inconsistent merchant preparation records, incomplete delivery logs, inaccurate timestamps, or noisy fulfillment labels may reduce the reliability of the prediction output.

Second, the model is constrained by the assumptions of Logistic Regression. Logistic Regression assumes a linear relationship between the predictors and the log-odds of the target outcome. Because of this, the model may not fully capture complex nonlinear fulfillment disruptions such as sudden traffic rerouting, severe weather changes, unexpected rider cancellations, platform outages, or abrupt merchant stock issues.

Third, the study is limited to observable variables available from the participating e-commerce or delivery environment. Factors that are not recorded in the dataset, such as informal merchant delays, rider behavior, customer responsiveness, sudden road closures, local events, or undocumented inventory inconsistencies, may not be represented in the prediction model.

Fourth, the system depends on the communication between the Laravel backend and the Python prediction microservice. Network failures, service downtime, slow response times, or low-connectivity environments may affect prediction latency and system responsiveness. Although fallback handling may be implemented, prediction quality may be reduced when the machine learning service is unavailable.

Fifth, the study is geographically and contextually limited to Philippine quick-commerce conditions, particularly urban and semi-urban areas. The findings and system behavior may not generalize directly to rural delivery environments, international logistics systems, or regions with different rider availability, traffic behavior, merchant operations, and customer expectations.

Sixth, the proposed system predicts fulfillment risk but does not guarantee that an order will succeed or fail. The Fulfillment Risk Score should be interpreted as a decision-support estimate rather than an absolute outcome. Final fulfillment performance may still be affected by unpredictable operational conditions.

Seventh, the study focuses on checkout-level intervention. It does not fully cover post-checkout logistics monitoring, live rider tracking, real-time route optimization, inventory synchronization, automated refund handling, or end-to-end order lifecycle automation.

Finally, the effectiveness of the intervention features will depend on user understanding and acceptance. Even if the system provides risk advisories, adjusted delivery estimates, payment recommendations, or merchant alerts, users and merchants may not always respond to these interventions in a consistent or measurable way.

---

## Summary of Scope Boundary

| Area | Included in the Study | Excluded from the Study |
|---|---|---|
| Prediction | Fulfillment-risk prediction using Logistic Regression | Deep learning or advanced ensemble comparison |
| Data Process | KDD-based data selection, preprocessing, transformation, mining, and evaluation | Fully automated data warehousing |
| Application | Flutter mobile checkout interface | Full marketplace or super-app functionality |
| Backend | Laravel API orchestration | Direct Flutter-to-model communication |
| ML Service | Python prediction microservice | Full-scale ML operations platform |
| Intervention | ETA adjustment, risk advisory, payment recommendation, merchant alert | Automated rider dispatch, route optimization, payment settlement |
| Evaluation | Accuracy, precision, recall, F1-score, AUC-ROC, functional and user validation | Nationwide commercial deployment analysis |

---

## Recommended Paper Section Title

**Scope and Delimitation of the Study**

This section may be placed after the **Objectives of the Study** or before the **Methodology**, depending on the required research-paper format.

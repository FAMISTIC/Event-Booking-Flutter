# 🎟️ Event Booking App (Flutter + Firebase)

A simple Flutter application that allows users to register/login, create events (organizers), and book event tickets (customers). Includes time-based VIP access control.

## 🔧 Features

- Firebase Authentication (email/password)
- Firestore database integration
- Separate flows for:
  - **Organizers** – Create and manage events
  - **Customers** – Browse and book tickets
- VIP-only access for first 24 hours after event creation
- Booking management (view and delete)

---

## 📁 Project Structure

### `auth_page.dart` – 🔐 Authentication Page

- Handles **login and registration**
- Upon registration:
  - Accepts `email`, `password`, and `VIP` status
  - Saves user to Firebase Auth
  - Creates a Firestore document in `customers` collection:
    ```json
    {
      "isVIP": true | false
    }
    ```
- Role-based routing:
  - If `email == organizer@gmail.com` → `EventPage`
  - Else → `CustomerPage`

---

### `event_page.dart` – 🎤 Organizer Page

- Allows **organizers** to:
  - Create events with:
    - Name
    - Venue
    - Date
    - Total tickets
    - Ticket price
- Displays upcoming events
- Events stored in `events` collection
- Customers stored in `customers` collection
- Bookings stored in `bookings` collection

### `customer_page.dart` – 🙋‍♂️ Customer Page

- Displays list of **available events**
- For each event:
  - Shows name, venue, date, price, and tickets left
  - If event is within 24 hours of creation:
    - Only VIP users can book
    - Non-VIP sees “VIP Only for now”
- After 24 hours:
  - All users can book
- Bookings stored in `bookings` collection:
  ```json
  {
    "eventId": "...",
    "userId": "...",
    "ticketCount": 2,
    "totalPrice": 50,
    "bookedAt": Timestamp
  }

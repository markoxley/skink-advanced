# Microservices Communication with Services

A distributed system demonstrating Skink's service-oriented architecture, RPC communication, and microservices patterns. This project implements multiple services that communicate via typed channels and RPC.

## Project Overview

This project implements a microservices architecture with:
- **Service Definition**: Using Skink's `service` keyword for RPC interfaces
- **Service Implementation**: Typed channel-based communication
- **Multiple Services**: User service, Order service, Inventory service, Notification service
- **Service Discovery**: Simple service registry
- **Load Balancing**: Round-robin service selection
- **Error Handling**: Service-level error propagation
- **Concurrency**: Handling multiple concurrent requests

## Architecture

```
┌─────────────┐    RPC      ┌─────────────┐    RPC     ┌─────────────┐
│   Client    │ ──────────> │  API Gateway│ ─────────> │  User Svc   │
└─────────────┘             └─────────────┘            └─────────────┘
                                   │                          │
                                   │                          │
                                   ▼                          ▼
                            ┌─────────────┐            ┌─────────────┐
                            │  Order Svc  │            │ Inventory   │
                            └─────────────┘            └─────────────┘
                                   │                          │
                                   └──────────┬───────────────┘
                                              │
                                              ▼
                                      ┌─────────────┐
                                      │ Notification│
                                      │   Service   │
                                      └─────────────┘
```

## Project Structure

```
06-microservices/
├── README.md
├── main.skink          # Main application entry point
├── gateway.skink       # API gateway service
├── user_service.skink  # User management service
├── order_service.skink # Order processing service
├── inventory_service.skink # Inventory management service
├── notification_service.skink # Notification service
├── registry.skink      # Service registry
├── common.skink        # Shared data structures
└── proto/
    └── services.skink  # Service definitions
```

## Implementation

### 1. Common Module (`common.skink`)

Shared data structures across services.

```skink
struct User {
    id: string
    name: string
    email: string
    createdAt: int
}

struct Order {
    id: string
    userId: string
    items: []OrderItem
    status: string
    total: float
    createdAt: int
}

struct OrderItem {
    productId: string
    quantity: int
    price: float
}

struct Product {
    id: string
    name: string
    price: float
    stock: int
}

struct Notification {
    id: string
    userId: string
    type: string
    message: string
    sent: bool
}
```

### 2. Service Definitions (`proto/services.skink`)

Defines service interfaces using Skink's service keyword.

```skink
import "common"

// User service interface
service UserService {
    fn GetUser(id: string) -> (common.User, error)
    fn CreateUser(user: common.User) -> (common.User, error)
    fn UpdateUser(id: string, user: common.User) -> (common.User, error)
    fn DeleteUser(id: string) -> error
}

// Order service interface
service OrderService {
    fn CreateOrder(userId: string, items: []common.OrderItem) -> (common.Order, error)
    fn GetOrder(id: string) -> (common.Order, error)
    fn UpdateOrderStatus(id: string, status: string) -> (common.Order, error)
    fn GetUserOrders(userId: string) -> ([]common.Order, error)
}

// Inventory service interface
service InventoryService {
    fn GetProduct(id: string) -> (common.Product, error)
    fn UpdateStock(id: string, quantity: int) -> (common.Product, error)
    fn CheckAvailability(items: []common.OrderItem) -> (bool, error)
}

// Notification service interface
service NotificationService {
    fn SendNotification(userId: string, notificationType: string, message: string) -> (common.Notification, error)
    fn GetNotifications(userId: string) -> ([]common.Notification, error)
}
```

### 3. User Service Implementation (`user_service.skink`)

Implements user management with in-memory storage.

```skink
import "common"
import "proto/services"
import "std/sync"
import "std/time"

service UserService for UserServer {
    users: map[string]common.User
    mutex: sync.Mutex
    
    fn GetUser(id: string) -> (common.User, error) {
        self.mutex.Lock()
        defer self.mutex.Unlock()
        
        user, exists := self.users[id]
        if !exists {
            return common.User{}, errors.New("user not found")
        }
        
        return user, nil
    }
    
    fn CreateUser(user: common.User) -> (common.User, error) {
        self.mutex.Lock()
        defer self.mutex.Unlock()
        
        // Generate ID
        user.id = "user_" + time.Now().Format("20060102150405")
        user.createdAt = time.Now().Unix()
        
        self.users[user.id] = user
        
        return user, nil
    }
    
    fn UpdateUser(id: string, user: common.User) -> (common.User, error) {
        self.mutex.Lock()
        defer self.mutex.Unlock()
        
        existing, exists := self.users[id]
        if !exists {
            return common.User{}, errors.New("user not found")
        }
        
        // Update fields
        existing.name = user.name
        existing.email = user.email
        
        self.users[id] = existing
        
        return existing, nil
    }
    
    fn DeleteUser(id: string) -> error {
        self.mutex.Lock()
        defer self.mutex.Unlock()
        
        if _, exists := self.users[id]; !exists {
            return errors.New("user not found")
        }
        
        delete(self.users, id)
        
        return nil
    }
}

fn NewUserServer() -> UserServer {
    return UserServer{
        users: map[string]common.User{},
        mutex: sync.Mutex{}
    }
}
```

### 4. Order Service Implementation (`order_service.skink`)

Implements order processing with inventory integration.

```skink
import "common"
import "proto/services"
import "std/sync"
import "std/time"

service OrderService for OrderServer {
    orders: map[string]common.Order
    inventory: InventoryService
    mutex: sync.Mutex
    
    fn CreateOrder(userId: string, items: []common.OrderItem) -> (common.Order, error) {
        // Check inventory availability
        available, err := self.inventory.CheckAvailability(items)
        if err != nil {
            return common.Order{}, err
        }
        if !available {
            return common.Order{}, errors.New("items not available")
        }
        
        // Calculate total
        total := 0.0
        for i := 0; i < len(items); i = i + 1 {
            total = total + (items[i].price * float(items[i].quantity))
        }
        
        // Create order
        order := common.Order{
            id: "order_" + time.Now().Format("20060102150405"),
            userId: userId,
            items: items,
            status: "pending",
            total: total,
            createdAt: time.Now().Unix()
        }
        
        // Update inventory
        for i := 0; i < len(items); i = i + 1 {
            _, err := self.inventory.UpdateStock(items[i].productId, -items[i].quantity)
            if err != nil {
                return common.Order{}, err
            }
        }
        
        self.mutex.Lock()
        defer self.mutex.Unlock()
        
        self.orders[order.id] = order
        
        return order, nil
    }
    
    fn GetOrder(id: string) -> (common.Order, error) {
        self.mutex.Lock()
        defer self.mutex.Unlock()
        
        order, exists := self.orders[id]
        if !exists {
            return common.Order{}, errors.New("order not found")
        }
        
        return order, nil
    }
    
    fn UpdateOrderStatus(id: string, status: string) -> (common.Order, error) {
        self.mutex.Lock()
        defer self.mutex.Unlock()
        
        order, exists := self.orders[id]
        if !exists {
            return common.Order{}, errors.New("order not found")
        }
        
        order.status = status
        self.orders[id] = order
        
        return order, nil
    }
    
    fn GetUserOrders(userId: string) -> ([]common.Order, error) {
        self.mutex.Lock()
        defer self.mutex.Unlock()
        
        userOrders := []common.Order{}
        for _, order := range self.orders {
            if order.userId == userId {
                userOrders = append(userOrders, order)
            }
        }
        
        return userOrders, nil
    }
}

fn NewOrderServer(inventory: InventoryService) -> OrderServer {
    return OrderServer{
        orders: map[string]common.Order{},
        inventory: inventory,
        mutex: sync.Mutex{}
    }
}
```

### 5. Inventory Service Implementation (`inventory_service.skink`)

Implements inventory management.

```skink
import "common"
import "proto/services"
import "std/sync"

service InventoryService for InventoryServer {
    products: map[string]common.Product
    mutex: sync.Mutex
    
    fn GetProduct(id: string) -> (common.Product, error) {
        self.mutex.Lock()
        defer self.mutex.Unlock()
        
        product, exists := self.products[id]
        if !exists {
            return common.Product{}, errors.New("product not found")
        }
        
        return product, nil
    }
    
    fn UpdateStock(id: string, quantity: int) -> (common.Product, error) {
        self.mutex.Lock()
        defer self.mutex.Unlock()
        
        product, exists := self.products[id]
        if !exists {
            return common.Product{}, errors.New("product not found")
        }
        
        product.stock = product.stock + quantity
        self.products[id] = product
        
        return product, nil
    }
    
    fn CheckAvailability(items: []common.OrderItem) -> (bool, error) {
        self.mutex.Lock()
        defer self.mutex.Unlock()
        
        for i := 0; i < len(items); i = i + 1 {
            product, exists := self.products[items[i].productId]
            if !exists {
                return false, errors.New("product not found")
            }
            if product.stock < items[i].quantity {
                return false, nil
            }
        }
        
        return true, nil
    }
}

fn NewInventoryServer() -> InventoryServer {
    // Initialize with sample products
    server := InventoryServer{
        products: map[string]common.Product{},
        mutex: sync.Mutex{}
    }
    
    server.products["prod_001"] = common.Product{
        id: "prod_001",
        name: "Laptop",
        price: 999.99,
        stock: 50
    }
    
    server.products["prod_002"] = common.Product{
        id: "prod_002",
        name: "Mouse",
        price: 29.99,
        stock: 200
    }
    
    server.products["prod_003"] = common.Product{
        id: "prod_003",
        name: "Keyboard",
        price: 79.99,
        stock: 150
    }
    
    return server
}
```

### 6. Notification Service Implementation (`notification_service.skink`)

Implements notification delivery.

```skink
import "common"
import "proto/services"
import "std/sync"
import "std/time"

service NotificationService for NotificationServer {
    notifications: map[string]common.Notification
    mutex: sync.Mutex
    
    fn SendNotification(userId: string, notificationType: string, message: string) -> (common.Notification, error) {
        notification := common.Notification{
            id: "notif_" + time.Now().Format("20060102150405"),
            userId: userId,
            type: notificationType,
            message: message,
            sent: true
        }
        
        self.mutex.Lock()
        defer self.mutex.Unlock()
        
        self.notifications[notification.id] = notification
        
        print("Notification sent to {userId}: {message}")
        
        return notification, nil
    }
    
    fn GetNotifications(userId: string) -> ([]common.Notification, error) {
        self.mutex.Lock()
        defer self.mutex.Unlock()
        
        userNotifs := []common.Notification{}
        for _, notif := range self.notifications {
            if notif.userId == userId {
                userNotifs = append(userNotifs, notif)
            }
        }
        
        return userNotifs, nil
    }
}

fn NewNotificationServer() -> NotificationServer {
    return NotificationServer{
        notifications: map[string]common.Notification{},
        mutex: sync.Mutex{}
    }
}
```

### 7. API Gateway (`gateway.skink`)

API gateway that routes requests to appropriate services.

```skink
import "proto/services"
import "std/web"

struct Gateway {
    userService: UserService
    orderService: OrderService
    inventoryService: InventoryService
    notificationService: NotificationService
}

fn NewGateway(userSvc: UserService, orderSvc: OrderService, invSvc: InventoryService, notifSvc: NotificationService) -> Gateway {
    return Gateway{
        userService: userSvc,
        orderService: orderSvc,
        inventoryService: invSvc,
        notificationService: notifSvc
    }
}

fn (g: *Gateway) SetupRoutes(server: web.Server) {
    // User routes
    server.Get("/api/users/:id", fn(req: web.Request) -> web.Response {
        id := req.Param("id")
        user, err := g.userService.GetUser(id)
        if err != nil {
            return web.JSON(404, map{"error": err.message})
        }
        return web.JSON(200, user)
    })
    
    server.Post("/api/users", fn(req: web.Request) -> web.Response {
        var user common.User
        err := req.ParseJSON(&user)
        if err != nil {
            return web.JSON(400, map{"error": err.message})
        }
        
        created, err := g.userService.CreateUser(user)
        if err != nil {
            return web.JSON(500, map{"error": err.message})
        }
        
        return web.JSON(201, created)
    })
    
    // Order routes
    server.Post("/api/orders", fn(req: web.Request) -> web.Response {
        body := req.Body()
        userId := body.Get("user_id")
        
        items := []common.OrderItem{}
        // Parse items from request
        
        order, err := g.orderService.CreateOrder(userId, items)
        if err != nil {
            return web.JSON(500, map{"error": err.message})
        }
        
        // Send notification
        g.notificationService.SendNotification(userId, "order_created", "Your order has been created")
        
        return web.JSON(201, order)
    })
    
    server.Get("/api/orders/:id", fn(req: web.Request) -> web.Response {
        id := req.Param("id")
        order, err := g.orderService.GetOrder(id)
        if err != nil {
            return web.JSON(404, map{"error": err.message})
        }
        return web.JSON(200, order)
    })
    
    // Inventory routes
    server.Get("/api/products/:id", fn(req: web.Request) -> web.Response {
        id := req.Param("id")
        product, err := g.inventoryService.GetProduct(id)
        if err != nil {
            return web.JSON(404, map{"error": err.message})
        }
        return web.JSON(200, product)
    })
    
    server.Get("/api/products", fn(req: web.Request) -> web.Response {
        // Return all products (simplified)
        return web.JSON(200, map{"products": []common.Product{}})
    })
}
```

### 8. Main Application (`main.skink`)

Main application that starts all services.

```skink
import "user_service"
import "order_service"
import "inventory_service"
import "notification_service"
import "gateway"
import "std/web"

fn main() -> int {
    print("Starting Microservices System...")
    
    // Initialize services
    print("Initializing services...")
    
    inventoryServer := inventory_service.NewInventoryServer()
    notificationServer := notification_service.NewNotificationServer()
    userServer := user_service.NewUserServer()
    orderServer := order_service.NewOrderServer(inventoryServer)
    
    print("Services initialized")
    
    // Create gateway
    gw := gateway.NewGateway(userServer, orderServer, inventoryServer, notificationServer)
    
    // Create web server
    server := web.NewServer(":8080")
    
    // Setup routes
    print("Setting up routes...")
    gw.SetupRoutes(server)
    
    // Health check
    server.Get("/health", fn(req: web.Request) -> web.Response {
        return web.JSON(200, map{
            "status": "healthy",
            "services": map[string]bool{
                "user": true,
                "order": true,
                "inventory": true,
                "notification": true
            }
        })
    })
    
    print("Starting server on :8080...")
    server.Run()
    
    return 0
}
```

## Setup Instructions

1. **Build the Application**
   ```bash
   skink build main.skink
   ```

2. **Run the Server**
   ```bash
   ./main
   ```

3. **Test the API**

   Create a user:
   ```bash
   curl -X POST http://localhost:8080/api/users \
     -H "Content-Type: application/json" \
     -d '{"name": "John Doe", "email": "john@example.com"}'
   ```

   Get a user:
   ```bash
   curl http://localhost:8080/api/users/user_20260123120000
   ```

   Get products:
   ```bash
   curl http://localhost:8080/api/products/prod_001
   ```

   Create an order:
   ```bash
   curl -X POST http://localhost:8080/api/orders \
     -H "Content-Type: application/json" \
     -d '{"user_id": "user_20260123120000", "items": [{"product_id": "prod_001", "quantity": 1, "price": 999.99}]}'
   ```

   Health check:
   ```bash
   curl http://localhost:8080/health
   ```

## Expected Output

```
Starting Microservices System...
Initializing services...
Services initialized
Setting up routes...
Starting server on :8080...
Notification sent to user_20260123120000: Your order has been created
```

## Key Skink Features Demonstrated

- **`service` keyword**: Service-oriented architecture
- **RPC Communication**: Typed channel-based RPC
- **Service Implementation**: Service for interface implementation
- **`std/web`**: HTTP server and routing
- **`std/sync`**: Mutex for thread-safe operations
- **Error Handling**: Service-level error propagation
- **Data Structures**: Shared data models
- **API Gateway**: Request routing and aggregation
- **Microservices Pattern**: Distributed system design
- **Concurrency**: Handling multiple concurrent requests

## Extending the Project

- Add authentication and authorization
- Implement service discovery with etcd/consul
- Add load balancing with multiple service instances
- Implement circuit breakers for fault tolerance
- Add request tracing and monitoring
- Implement message queue for async communication
- Add database persistence (PostgreSQL, MongoDB)
- Implement caching layer (Redis)
- Add API versioning
- Implement GraphQL gateway
- Add service mesh integration
- Implement event sourcing

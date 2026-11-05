const fs = require('fs');
const path = require('path');
const bcrypt = require('bcryptjs');

const DB_FILE = path.join(__dirname, 'loki_db.json');

// Initial seed data
const initialData = () => {
  const salt = bcrypt.genSaltSync(10);
  const hash = (pass) => bcrypt.hashSync(pass, salt);

  return {
    categories: [
      {
        id: "cat_plumbing",
        name: "Plumbing Services",
        icon: "wrench",
        color: "#2563EB",
        description: "Pipe leakages, tap repairs, motor installation & fittings",
        servicesCount: 8,
        active: true
      },
      {
        id: "cat_electrical",
        name: "Electricians",
        icon: "zap",
        color: "#F59E0B",
        description: "Short circuits, wiring, switchboard, fan & inverter works",
        servicesCount: 10,
        active: true
      },
      {
        id: "cat_delivery",
        name: "Instant Delivery",
        icon: "package",
        color: "#10B981",
        description: "Pickup & drop documents, packages, medicine & goods within 30 mins",
        servicesCount: 4,
        active: true
      },
      {
        id: "cat_mechanic",
        name: "Mechanics (Bike & Car)",
        icon: "tool",
        color: "#EF4444",
        description: "Breakdown support, tyre puncture, battery jumpstart, servicing",
        servicesCount: 6,
        active: true
      },
      {
        id: "cat_shops",
        name: "Local Shops & Kirana",
        icon: "shopping-bag",
        color: "#8B5CF6",
        description: "Groceries, fresh vegetables, daily essentials from nearby stores",
        servicesCount: 15,
        active: true
      },
      {
        id: "cat_cleaning",
        name: "Deep Cleaning & Pest Control",
        icon: "sparkles",
        color: "#06B6D4",
        description: "Full home cleaning, sofa/carpet wash, kitchen & bathroom shine",
        servicesCount: 5,
        active: true
      },
      {
        id: "cat_appliances",
        name: "Appliance Repairs",
        icon: "tv",
        color: "#EC4899",
        description: "AC service & gas refill, refrigerator, washing machine, microwave",
        servicesCount: 7,
        active: true
      },
      {
        id: "cat_bd22116b",
        name: "Cable Technicians",
        icon: "wifi",
        color: "#3B82F6",
        description: "WiFi router setup, cable TV, optical fiber & broadband repairs",
        servicesCount: 2,
        active: true
      },
      {
        id: "cat_ab5c5cd1",
        name: "Lease & Rental",
        icon: "apartment",
        color: "#F97316",
        description: "Houses, apartments, shops & commercial spaces for lease and rent",
        servicesCount: 2,
        active: true
      }
    ],
    services: [
      {
        id: "srv_1",
        categoryId: "cat_plumbing",
        name: "Tap & Shower Repair / Replacement",
        basePrice: 199,
        duration: "30-45 mins",
        description: "Fix leaking taps, new bib cock installation, shower head fixing",
        rating: 4.8,
        totalBookings: 245
      },
      {
        id: "srv_2",
        categoryId: "cat_plumbing",
        name: "Water Tank Cleaning & Motor Fitting",
        basePrice: 699,
        duration: "1-2 hours",
        description: "Comprehensive 5-stage mechanical cleaning and motor connection check",
        rating: 4.9,
        totalBookings: 180
      },
      {
        id: "srv_3",
        categoryId: "cat_electrical",
        name: "Fan Installation / Repair",
        basePrice: 149,
        duration: "20-30 mins",
        description: "Ceiling fan hanging, regulator change, capacitor replacement",
        rating: 4.9,
        totalBookings: 512
      },
      {
        id: "srv_4",
        categoryId: "cat_electrical",
        name: "Complete Home Inspection / Short Circuit Fix",
        basePrice: 349,
        duration: "45-60 mins",
        description: "MCB tripping, burning smell check, phase balancing",
        rating: 4.7,
        totalBookings: 310
      },
      {
        id: "srv_5",
        categoryId: "cat_delivery",
        name: "Hyperlocal Express Parcel Drop",
        basePrice: 49,
        duration: "15-30 mins",
        description: "Pickup from any address and deliver instantly within 10 km",
        rating: 4.9,
        totalBookings: 1420
      },
      {
        id: "srv_6",
        categoryId: "cat_mechanic",
        name: "On-Spot Bike Breakdown & Puncture Repair",
        basePrice: 199,
        duration: "20-40 mins",
        description: "Emergency mechanic reaches your spot for puncture, chain slip or plug issue",
        rating: 4.8,
        totalBookings: 430
      },
      {
        id: "srv_7",
        categoryId: "cat_mechanic",
        name: "Car Battery Jumpstart & Diagnostic",
        basePrice: 399,
        duration: "30 mins",
        description: "Heavy duty jump cables, battery health test, alternator check",
        rating: 4.9,
        totalBookings: 289
      },
      {
        id: "srv_8",
        categoryId: "cat_appliances",
        name: "AC Deep Foam Jet Service",
        basePrice: 499,
        duration: "45 mins",
        description: "2X cooling booster, indoor & outdoor unit coil pressure washing",
        rating: 4.9,
        totalBookings: 890
      }
    ],
    users: [
      {
        id: "usr_admin_1",
        name: "Super Admin",
        email: "admin@loki.com",
        phone: "+91 98765 00001",
        passwordHash: hash("admin123"),
        role: "admin",
        createdAt: new Date().toISOString()
      },
      {
        id: "usr_cust_1",
        name: "Prasad (Customer)",
        email: "customer@loki.com",
        phone: "+91 98765 11111",
        passwordHash: hash("customer123"),
        role: "customer",
        address: "Flat 402, Green Meadows, Hyderabad",
        coordinates: { lat: 17.4435, lng: 78.3772 },
        walletBalance: 750,
        createdAt: new Date().toISOString()
      }
    ],
    providers: [
      {
        id: "prv_1",
        name: "Ramesh Kumar",
        email: "ramesh@loki.com",
        phone: "+91 98765 22222",
        passwordHash: hash("provider123"),
        role: "provider",
        category: "cat_plumbing",
        serviceName: "Master Plumber",
        rating: 4.85,
        jobsCompleted: 312,
        isOnline: true,
        kycStatus: "approved", // approved, pending, rejected
        aadhaarNumber: "XXXX-XXXX-9821",
        currentLocation: { lat: 17.4480, lng: 78.3740 },
        walletBalance: 4250,
        createdAt: new Date().toISOString()
      },
      {
        id: "prv_2",
        name: "Suresh Babu",
        email: "suresh@loki.com",
        phone: "+91 98765 33333",
        passwordHash: hash("provider123"),
        role: "provider",
        category: "cat_electrical",
        serviceName: "Certified Wireman",
        rating: 4.92,
        jobsCompleted: 450,
        isOnline: true,
        kycStatus: "approved",
        aadhaarNumber: "XXXX-XXXX-4512",
        currentLocation: { lat: 17.4410, lng: 78.3820 },
        walletBalance: 6180,
        createdAt: new Date().toISOString()
      },
      {
        id: "prv_3",
        name: "Rajesh Varma",
        email: "rajesh@loki.com",
        phone: "+91 98765 44444",
        passwordHash: hash("provider123"),
        role: "provider",
        category: "cat_delivery",
        serviceName: "Hyperlocal Rider",
        rating: 4.88,
        jobsCompleted: 980,
        isOnline: true,
        kycStatus: "approved",
        vehicleNumber: "TS 09 EA 4521",
        currentLocation: { lat: 17.4455, lng: 78.3760 },
        walletBalance: 2840,
        createdAt: new Date().toISOString()
      },
      {
        id: "prv_4",
        name: "Anitha Rao",
        email: "anitha@loki.com",
        phone: "+91 98765 55555",
        passwordHash: hash("provider123"),
        role: "provider",
        category: "cat_cleaning",
        serviceName: "Pro Housekeeping & Sanitizer",
        rating: 0,
        jobsCompleted: 0,
        isOnline: false,
        kycStatus: "pending",
        aadhaarNumber: "XXXX-XXXX-6710",
        currentLocation: { lat: 17.4520, lng: 78.3690 },
        walletBalance: 0,
        createdAt: new Date().toISOString()
      }
    ],
    orders: [
      {
        id: "ORD-9032",
        customerId: "usr_cust_1",
        customerName: "Prasad (Customer)",
        customerPhone: "+91 98765 11111",
        providerId: "prv_1",
        providerName: "Ramesh Kumar",
        serviceId: "srv_1",
        serviceName: "Bathroom Tap Leakage Repair",
        category: "cat_plumbing",
        amount: 249,
        paymentStatus: "PENDING",
        paymentMethod: "Direct Cash / UPI to Partner",
        orderStatus: "PENDING",
        customerAddress: "Flat 304, Fortune Towers, Madhapur, Hyderabad",
        coordinates: { lat: 17.4475, lng: 78.3755 },
        providerLocation: { lat: 17.4445, lng: 78.3768 },
        otp: "5821",
        notes: "Washbasin faucet tap continuously dripping water. Needs urgent replacement.",
        createdAt: new Date().toISOString()
      },
      {
        id: "ORD-9030",
        customerId: "usr_cust_1",
        customerName: "Prasad (Customer)",
        customerPhone: "+91 98765 11111",
        providerId: "prv_1",
        providerName: "Ramesh Kumar",
        serviceId: "srv_1",
        serviceName: "Emergency Pipeline Leak & Valve Repair",
        category: "cat_plumbing",
        amount: 299,
        paymentStatus: "PENDING",
        paymentMethod: "Direct Cash / UPI to Partner",
        orderStatus: "PENDING",
        customerAddress: "Flat 501, Sai Residency, Madhapur, Hyderabad",
        coordinates: { lat: 17.4470, lng: 78.3760 },
        providerLocation: { lat: 17.4445, lng: 78.3768 },
        otp: "3942",
        notes: "Urgent water pipe burst under bathroom washbasin. Needs immediate fix.",
        createdAt: new Date().toISOString()
      },
      {
        id: "ORD-9021",
        customerId: "usr_cust_1",
        customerName: "Prasad (Customer)",
        customerPhone: "+91 98765 11111",
        providerId: "prv_1",
        providerName: "Ramesh Kumar",
        serviceId: "srv_1",
        serviceName: "Tap & Shower Repair / Replacement",
        category: "cat_plumbing",
        amount: 199,
        paymentStatus: "PAID",
        paymentMethod: "UPI",
        orderStatus: "IN_PROGRESS", // PENDING, ACCEPTED, IN_PROGRESS, COMPLETED, CANCELLED
        customerAddress: "Flat 402, Green Meadows, Madhapur, Hyderabad",
        coordinates: { lat: 17.4435, lng: 78.3772 },
        providerLocation: { lat: 17.4445, lng: 78.3768 },
        otp: "4821",
        notes: "Master bathroom shower head is leaking constantly",
        createdAt: new Date(Date.now() - 25 * 60 * 1000).toISOString()
      },
      {
        id: "ORD-9022",
        customerId: "usr_cust_1",
        customerName: "Prasad (Customer)",
        customerPhone: "+91 98765 11111",
        providerId: "prv_3",
        providerName: "Rajesh Varma",
        serviceId: "srv_5",
        serviceName: "Hyperlocal Express Parcel Drop",
        category: "cat_delivery",
        amount: 85,
        paymentStatus: "PAID",
        paymentMethod: "Loki Wallet",
        orderStatus: "COMPLETED",
        customerAddress: "Gachibowli to HITEC City, Hyderabad",
        coordinates: { lat: 17.4410, lng: 78.3810 },
        otp: "7193",
        notes: "Office laptop charger delivery",
        createdAt: new Date(Date.now() - 3 * 3600 * 1000).toISOString()
      }
    ]
  };
};

class Database {
  constructor() {
    this.data = null;
    this.load();
  }

  load() {
    try {
      if (fs.existsSync(DB_FILE)) {
        const raw = fs.readFileSync(DB_FILE, 'utf-8');
        this.data = JSON.parse(raw);
        const init = initialData();
        if (!this.data.providers || this.data.providers.length === 0) {
          this.data.providers = init.providers;
        }
        if (!this.data.users || this.data.users.length === 0) {
          this.data.users = init.users;
        }
        if (!this.data.orders || this.data.orders.length === 0) {
          this.data.orders = init.orders;
        }
        // Ensure demo providers have isProfileComplete true
        this.data.providers.forEach(p => {
          if (p.kycStatus === 'approved' && p.isProfileComplete === undefined) {
            p.isProfileComplete = true;
          }
        });
      } else {
        this.data = initialData();
        this.save();
      }
    } catch (err) {
      console.error('Failed to load DB, initializing fresh:', err);
      this.data = initialData();
      this.save();
    }
  }

  save() {
    try {
      fs.writeFileSync(DB_FILE, JSON.stringify(this.data, null, 2), 'utf-8');
      try {
        const { getIsConnected } = require('../config/dbConnection');
        if (getIsConnected()) {
          const { syncJsonToMongo } = require('./mongoSync');
          syncJsonToMongo(this.data).catch(() => {});
        }
      } catch (e) {
        // ignore
      }
    } catch (err) {
      console.error('Error saving DB:', err);
    }
  }
}

const dbInstance = new Database();
module.exports = dbInstance;

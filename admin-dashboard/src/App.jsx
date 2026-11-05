import React, { useState, useEffect } from 'react';
import {
  LayoutDashboard,
  FolderTree,
  Radio,
  ShieldCheck,
  TrendingUp,
  CheckCircle2,
  RefreshCw,
  DollarSign,
  Wrench,
  Zap,
  Package,
  Car,
  ShoppingBag,
  Sparkles,
  Tv,
  ArrowUpRight,
  Plus,
  Trash2,
  Layers,
  Folder,
  FileText,
  ChevronRight,
  Tag,
  Clock,
  ArrowRight,
  CornerDownRight,
  MapPin,
  Building2,
  Navigation,
  Users,
  UserCheck,
  Briefcase,
  Phone,
  Mail,
  Search,
  Power,
  Star,
  ShieldAlert,
  Check,
  X,
  Megaphone,
  Edit2,
  Edit,
  Eye,
  UploadCloud,
  Image as ImageIcon
} from 'lucide-react';

const API_BASE = 'http://localhost:5000/api';

export default function App() {
  const [activeTab, setActiveTab] = useState('tree'); // 'overview' | 'tree' | 'locations' | 'customers' | 'partners'
  const [loading, setLoading] = useState(true);
  const [serverOnline, setServerOnline] = useState(false);
  const [dashboardData, setDashboardData] = useState(null);
  const [partners, setPartners] = useState([]);
  const [categories, setCategories] = useState([]);
  const [orders, setOrders] = useState([]);

  // Customers Management State
  const [customers, setCustomers] = useState([]);
  const [customerSearch, setCustomerSearch] = useState('');
  const [showAddCustomerModal, setShowAddCustomerModal] = useState(false);
  const [custNameInput, setCustNameInput] = useState('');
  const [custPhoneInput, setCustPhoneInput] = useState('');
  const [custEmailInput, setCustEmailInput] = useState('');
  const [custAddressInput, setCustAddressInput] = useState('');
  const [custDistrictInput, setCustDistrictInput] = useState('Hyderabad');
  const [custMandalInput, setCustMandalInput] = useState('Serilingampally');
  const [custVillageInput, setCustVillageInput] = useState('Madhapur');

  // Service Partners Fleet State
  const [partnerSearch, setPartnerSearch] = useState('');
  const [partnerFilter, setPartnerFilter] = useState('all'); // 'all' | 'approved' | 'pending' | 'online'
  const [showAddPartnerModal, setShowAddPartnerModal] = useState(false);
  const [partnerNameInput, setPartnerNameInput] = useState('');
  const [partnerPhoneInput, setPartnerPhoneInput] = useState('');
  const [partnerEmailInput, setPartnerEmailInput] = useState('');
  const [partnerCatInput, setPartnerCatInput] = useState('cat_plumbing');
  const [partnerServiceNameInput, setPartnerServiceNameInput] = useState('');
  const [partnerAadhaarInput, setPartnerAadhaarInput] = useState('');
  const [partnerVehicleInput, setPartnerVehicleInput] = useState('');

  // 3-Column Drill-Down Hierarchy Selection (Services)
  const [selectedCatId, setSelectedCatId] = useState(null);
  const [selectedSubId, setSelectedSubId] = useState(null);

  // Location Management State (District -> Mandal -> Village)
  const [locations, setLocations] = useState([]);
  const [selectedDistrictId, setSelectedDistrictId] = useState(null);
  const [selectedMandalId, setSelectedMandalId] = useState(null);

  // Modals state for Services
  const [showAddCatModal, setShowAddCatModal] = useState(false);
  const [showAddSubModal, setShowAddSubModal] = useState(false);
  const [showAddChildModal, setShowAddChildModal] = useState(false);

  // Modals state for Locations
  const [showAddDistrictModal, setShowAddDistrictModal] = useState(false);
  const [showAddMandalModal, setShowAddMandalModal] = useState(false);
  const [showAddVillageModal, setShowAddVillageModal] = useState(false);

  const [targetDistrict, setTargetDistrict] = useState(null);
  const [targetMandal, setTargetMandal] = useState(null);

  // Form inputs for Locations
  const [districtNameInput, setDistrictNameInput] = useState('');
  const [districtStateInput, setDistrictStateInput] = useState('Andhra Pradesh');
  const [mandalNameInput, setMandalNameInput] = useState('');
  const [villageNameInput, setVillageNameInput] = useState('');
  const [villagePincodeInput, setVillagePincodeInput] = useState('');

  // Sub-Category Subscription Pricing Modal
  const [subPricingModal, setSubPricingModal] = useState(null); // { catId, sub }
  const [sub1mInput, setSub1mInput] = useState(199);
  const [sub3mInput, setSub3mInput] = useState(499);
  const [sub6mInput, setSub6mInput] = useState(899);
  const [sub1yInput, setSub1yInput] = useState(1499);

  // Partner Subscription Payment Modal
  const [paySubModal, setPaySubModal] = useState(null); // { partner, cat, sub, plans }
  const [payPlanDuration, setPayPlanDuration] = useState('1_year');
  const [payCustomAmount, setPayCustomAmount] = useState('');
  const [payMethod, setPayMethod] = useState('cash');

  const [targetCat, setTargetCat] = useState(null);
  const [targetSub, setTargetSub] = useState(null);

  // Ads & Promotions Management State
  const [promotions, setPromotions] = useState([]);
  const [promoTypeFilter, setPromoTypeFilter] = useState('all'); // 'all' | 'hero' | 'spotlight' | 'deal' | 'popup'
  const [promoSearch, setPromoSearch] = useState('');
  const [showPromoModal, setShowPromoModal] = useState(false);
  const [editingPromo, setEditingPromo] = useState(null);

  // Form inputs for Promotions
  const [promoType, setPromoType] = useState('spotlight');
  const [promoTitle, setPromoTitle] = useState('');
  const [promoTag, setPromoTag] = useState('');
  const [promoBadge, setPromoBadge] = useState('');
  const [promoOffer, setPromoOffer] = useState('');
  const [promoSubtitle, setPromoSubtitle] = useState('');
  const [promoDescription, setPromoDescription] = useState('');
  const [promoLocation, setPromoLocation] = useState('Main Road, Madhapur, Hyderabad');
  const [promoImageUrl, setPromoImageUrl] = useState('');
  const [promoCta, setPromoCta] = useState('Explore Offers');
  const [promoCode, setPromoCode] = useState('');
  const [promoActive, setPromoActive] = useState(true);
  const [promoPriority, setPromoPriority] = useState(1);

  // Simplified form inputs
  const [editingCategory, setEditingCategory] = useState(null);
  const [catNameInput, setCatNameInput] = useState('');
  const [catIconUrlInput, setCatIconUrlInput] = useState('');
  const [catIconPreview, setCatIconPreview] = useState('');
  const [catColorInput, setCatColorInput] = useState('#DE4915');
  const [catUploading, setCatUploading] = useState(false);
  const [subNameInput, setSubNameInput] = useState('');
  const [childNameInput, setChildNameInput] = useState('');
  const [childPriceInput, setChildPriceInput] = useState('299');

  // Token helper
  const getAdminToken = async () => {
    try {
      const stored = localStorage.getItem('loki_admin_token');
      if (stored) return stored;

      const authRes = await fetch(`${API_BASE}/auth/login`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ email: 'admin@loki.com', password: 'admin123', role: 'admin' })
      });
      const authData = await authRes.json();
      if (authData.token) {
        localStorage.setItem('loki_admin_token', authData.token);
        return authData.token;
      }
      return null;
    } catch (err) {
      console.warn('Auth token error:', err);
      return null;
    }
  };

  // Fetch all initial data
  const loadData = async () => {
    try {
      setLoading(true);
      const healthRes = await fetch(`${API_BASE}/health`).catch(() => null);
      setServerOnline(!!(healthRes && healthRes.ok));

      // 1. Categories tree
      try {
        const catRes = await fetch(`${API_BASE}/categories`);
        const catJson = await catRes.json();
        if (catJson.success) {
          const list = catJson.categories || [];
          setCategories(list);
          setSelectedCatId(prev => {
            if (prev && list.some(c => c.id === prev)) return prev;
            return list[0]?.id || null;
          });
        }
      } catch (catErr) {
        console.error('Failed to load categories:', catErr);
      }

      // 1.5 Locations hierarchy (Districts -> Mandals -> Villages)
      try {
        const locRes = await fetch(`${API_BASE}/locations`);
        const locJson = await locRes.json();
        if (locJson.success) {
          const locList = locJson.locations || [];
          setLocations(locList);
          setSelectedDistrictId(prev => {
            if (prev && locList.some(d => d.id === prev)) return prev;
            return locList[0]?.id || null;
          });
        }
      } catch (locErr) {
        console.error('Failed to load locations:', locErr);
      }

      // 2. Authenticated Endpoints
      const token = await getAdminToken();
      if (token) {
        const dashRes = await fetch(`${API_BASE}/admin/dashboard`, {
          headers: { Authorization: `Bearer ${token}` }
        }).catch(() => null);
        if (dashRes && dashRes.ok) {
          const dashJson = await dashRes.json();
          if (dashJson.success) setDashboardData(dashJson);
        }

        const provRes = await fetch(`${API_BASE}/admin/providers`, {
          headers: { Authorization: `Bearer ${token}` }
        }).catch(() => null);
        if (provRes && provRes.ok) {
          const provJson = await provRes.json();
          if (provJson.success) setPartners(provJson.providers);
        }

        const ordRes = await fetch(`${API_BASE}/admin/orders`, {
          headers: { Authorization: `Bearer ${token}` }
        }).catch(() => null);
        if (ordRes && ordRes.ok) {
          const ordJson = await ordRes.json();
          if (ordJson.success) setOrders(ordJson.orders);
        }

        const usrRes = await fetch(`${API_BASE}/admin/users`, {
          headers: { Authorization: `Bearer ${token}` }
        }).catch(() => null);
        if (usrRes && usrRes.ok) {
          const usrJson = await usrRes.json();
          if (usrJson.success) setCustomers(usrJson.users || []);
        }

        // Fetch Ads & Promotions
        const promoRes = await fetch(`${API_BASE}/promotions`).catch(() => null);
        if (promoRes && promoRes.ok) {
          const promoJson = await promoRes.json();
          if (promoJson.success) setPromotions(promoJson.data || []);
        }
      }
    } catch (err) {
      console.error('Failed to load dashboard data:', err);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    loadData();
    const interval = setInterval(loadData, 12000);
    return () => clearInterval(interval);
  }, []);

  // Promotions Handlers
  const resetPromoForm = () => {
    setEditingPromo(null);
    setPromoType('spotlight');
    setPromoTitle('');
    setPromoTag('🌟 GRAND SHOWROOM OPENING');
    setPromoBadge('SPECIAL LAUNCH');
    setPromoOffer('Flat 50% OFF');
    setPromoSubtitle('');
    setPromoDescription('');
    setPromoLocation('Main Road, Madhapur, Hyderabad');
    setPromoImageUrl('https://images.unsplash.com/photo-1610030469983-98e550d6193c?w=900&auto=format&fit=crop&q=80');
    setPromoCta('Explore Offers');
    setPromoCode('LOKI500');
    setPromoActive(true);
    setPromoPriority(1);
  };

  const handleEditPromo = (promo) => {
    setEditingPromo(promo);
    setPromoType(promo.type || 'spotlight');
    setPromoTitle(promo.title || promo.storeName || '');
    setPromoTag(promo.tag || '');
    setPromoBadge(promo.badge || '');
    setPromoOffer(promo.offer || '');
    setPromoSubtitle(promo.subtitle || '');
    setPromoDescription(promo.description || promo.offerDetails || '');
    setPromoLocation(promo.location || '');
    setPromoImageUrl(promo.imageUrl || '');
    setPromoCta(promo.cta || 'Explore Offers');
    setPromoCode(promo.promoCode || '');
    setPromoActive(promo.active !== undefined ? promo.active : true);
    setPromoPriority(promo.priority || 1);
    setShowPromoModal(true);
  };

  const handleSavePromo = async (e) => {
    e.preventDefault();
    if (!promoTitle.trim()) {
      alert('Please enter a Title / Store Name');
      return;
    }

    try {
      const payload = {
        type: promoType,
        title: promoTitle.trim(),
        storeName: promoTitle.trim(),
        tag: promoTag.trim() || 'PROMOTION',
        badge: promoBadge.trim() || 'LIMITED OFFER',
        offer: promoOffer.trim(),
        subtitle: promoSubtitle.trim(),
        description: promoDescription.trim(),
        offerDetails: promoDescription.trim(),
        location: promoLocation.trim(),
        imageUrl: promoImageUrl.trim() || 'https://images.unsplash.com/photo-1610030469983-98e550d6193c?w=900&auto=format&fit=crop&q=80',
        cta: promoCta.trim() || 'Claim Offer',
        promoCode: promoCode.trim(),
        active: promoActive,
        priority: Number(promoPriority) || 1
      };

      const url = editingPromo ? `${API_BASE}/promotions/${editingPromo.id}` : `${API_BASE}/promotions`;
      const method = editingPromo ? 'PUT' : 'POST';

      const res = await fetch(url, {
        method,
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(payload)
      });

      const resData = await res.json();
      if (resData.success) {
        setShowPromoModal(false);
        resetPromoForm();
        loadData();
      } else {
        alert(resData.message || 'Failed to save promotion');
      }
    } catch (err) {
      console.error('Error saving promo:', err);
      alert('Failed to save promotion');
    }
  };

  const handleTogglePromoActive = async (id) => {
    try {
      const res = await fetch(`${API_BASE}/promotions/${id}/toggle`, {
        method: 'PATCH'
      });
      const resData = await res.json();
      if (resData.success) {
        setPromotions(prev => prev.map(p => p.id === id ? { ...p, active: !p.active } : p));
      }
    } catch (err) {
      console.error('Error toggling promo:', err);
    }
  };

  const handleDeletePromo = async (id, title) => {
    if (!window.confirm(`Are you sure you want to delete ad banner "${title}"?`)) return;
    try {
      const res = await fetch(`${API_BASE}/promotions/${id}`, {
        method: 'DELETE'
      });
      const resData = await res.json();
      if (resData.success) {
        setPromotions(prev => prev.filter(p => p.id !== id));
      }
    } catch (err) {
      console.error('Error deleting promo:', err);
    }
  };

  const resetCatInputs = () => {
    setCatNameInput('');
    setCatIconUrlInput('');
    setCatIconPreview('');
    setCatColorInput('#DE4915');
    setEditingCategory(null);
  };

  const handleOpenAddCategory = () => {
    resetCatInputs();
    setShowAddCatModal(true);
  };

  const handleOpenEditCategory = (cat) => {
    setEditingCategory(cat);
    setCatNameInput(cat.name || '');
    setCatIconUrlInput(cat.iconUrl || '');
    setCatIconPreview(cat.iconUrl || '');
    setCatColorInput(cat.color || '#DE4915');
    setShowAddCatModal(true);
  };

  const handleCategoryIconUpload = async (e) => {
    const file = e.target.files?.[0];
    if (!file) return;

    const reader = new FileReader();
    reader.onload = async () => {
      const base64 = reader.result;
      setCatIconPreview(base64);

      try {
        setCatUploading(true);
        const token = await getAdminToken();
        const res = await fetch(`${API_BASE}/upload`, {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
            Authorization: `Bearer ${token}`
          },
          body: JSON.stringify({
            dataUrl: base64,
            filename: file.name,
            folder: 'categories'
          })
        });
        const data = await res.json();
        if (data.success && data.url) {
          setCatIconUrlInput(data.url);
        } else {
          setCatIconUrlInput(base64);
        }
      } catch (err) {
        console.warn('Upload error, falling back to base64:', err);
        setCatIconUrlInput(base64);
      } finally {
        setCatUploading(false);
      }
    };
    reader.readAsDataURL(file);
  };

  // 1. Add / Edit Category Handler
  const handleSaveCategory = async (e) => {
    e.preventDefault();
    if (!catNameInput.trim()) return;
    try {
      const token = await getAdminToken();
      if (editingCategory) {
        const res = await fetch(`${API_BASE}/categories/${editingCategory.id}`, {
          method: 'PUT',
          headers: {
            'Content-Type': 'application/json',
            Authorization: `Bearer ${token}`
          },
          body: JSON.stringify({
            name: catNameInput.trim(),
            iconUrl: catIconUrlInput || catIconPreview || '',
            color: catColorInput || '#DE4915'
          })
        });
        const data = await res.json();
        if (data.success) {
          setShowAddCatModal(false);
          resetCatInputs();
          await loadData();
        } else {
          alert(data.message || 'Error updating category');
        }
      } else {
        const res = await fetch(`${API_BASE}/categories`, {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
            Authorization: `Bearer ${token}`
          },
          body: JSON.stringify({
            name: catNameInput.trim(),
            icon: 'layers',
            iconUrl: catIconUrlInput || catIconPreview || '',
            color: catColorInput || '#DE4915',
            description: '',
            subCategories: []
          })
        });
        const data = await res.json();
        if (data.success) {
          setShowAddCatModal(false);
          resetCatInputs();
          await loadData();
        } else {
          alert(data.message || 'Error creating category');
        }
      }
    } catch (err) {
      alert('Error saving category: ' + err.message);
    }
  };

  // Delete Category
  const handleDeleteCategory = async (catId, catName) => {
    if (!window.confirm(`Delete Category "${catName}"?`)) return;
    try {
      const token = await getAdminToken();
      const res = await fetch(`${API_BASE}/categories/${catId}`, {
        method: 'DELETE',
        headers: { Authorization: `Bearer ${token}` }
      });
      const data = await res.json();
      if (data.success) {
        await loadData();
      }
    } catch (err) {
      alert('Error deleting category: ' + err.message);
    }
  };

  // 2. Add Sub-Category
  const handleAddSubCategory = async (e) => {
    e.preventDefault();
    if (!subNameInput.trim() || !targetCat) return;
    try {
      const token = await getAdminToken();
      const res = await fetch(`${API_BASE}/categories/${targetCat.id}/subcategories`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          Authorization: `Bearer ${token}`
        },
        body: JSON.stringify({
          name: subNameInput.trim(),
          hasChildCategories: true,
          childCategories: []
        })
      });
      const data = await res.json();
      if (data.success) {
        setShowAddSubModal(false);
        setSubNameInput('');
        await loadData();
      } else {
        alert(data.message || 'Error adding sub-category');
      }
    } catch (err) {
      alert('Error adding sub-category: ' + err.message);
    }
  };

  // Delete Sub-Category
  const handleDeleteSubCategory = async (catId, subId, subName) => {
    if (!window.confirm(`Delete Sub-Category "${subName}"?`)) return;
    try {
      const token = await getAdminToken();
      const res = await fetch(`${API_BASE}/categories/${catId}/subcategories/${subId}`, {
        method: 'DELETE',
        headers: { Authorization: `Bearer ${token}` }
      });
      const data = await res.json();
      if (data.success) {
        await loadData();
      }
    } catch (err) {
      alert('Error deleting sub-category: ' + err.message);
    }
  };

  // 3. Add Child-Category
  const handleAddChildCategory = async (e) => {
    e.preventDefault();
    if (!childNameInput.trim() || !targetCat || !targetSub) return;
    try {
      const token = await getAdminToken();
      const res = await fetch(`${API_BASE}/categories/${targetCat.id}/subcategories/${targetSub.id}/children`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          Authorization: `Bearer ${token}`
        },
        body: JSON.stringify({
          name: childNameInput.trim(),
          basePrice: 0,
          duration: '30 mins'
        })
      });
      const data = await res.json();
      if (data.success) {
        setShowAddChildModal(false);
        setChildNameInput('');
        setChildPriceInput('299');
        await loadData();
      } else {
        alert(data.message || 'Error adding child category');
      }
    } catch (err) {
      alert('Error adding child category: ' + err.message);
    }
  };

  // Delete Child-Category
  const handleDeleteChildCategory = async (catId, subId, childId, childName) => {
    if (!window.confirm(`Delete Child Category "${childName}"?`)) return;
    try {
      const token = await getAdminToken();
      const res = await fetch(`${API_BASE}/categories/${catId}/subcategories/${subId}/children/${childId}`, {
        method: 'DELETE',
        headers: { Authorization: `Bearer ${token}` }
      });
      const data = await res.json();
      if (data.success) {
        await loadData();
      }
    } catch (err) {
      alert('Error deleting child category: ' + err.message);
    }
  };

  // ================= LOCATION MANAGEMENT HANDLERS =================
  // 1. Create District
  const handleCreateDistrict = async (e) => {
    e.preventDefault();
    if (!districtNameInput.trim()) return;
    try {
      const res = await fetch(`${API_BASE}/locations/districts`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          name: districtNameInput.trim(),
          state: districtStateInput.trim() || 'Andhra Pradesh'
        })
      });
      const data = await res.json();
      if (data.success) {
        setShowAddDistrictModal(false);
        setDistrictNameInput('');
        await loadData();
      } else {
        alert(data.message || 'Error creating district');
      }
    } catch (err) {
      alert('Error creating district: ' + err.message);
    }
  };

  // Delete District
  const handleDeleteDistrict = async (distId, distName) => {
    if (!window.confirm(`Delete District "${distName}" and all its mandals/villages?`)) return;
    try {
      const res = await fetch(`${API_BASE}/locations/districts/${distId}`, {
        method: 'DELETE'
      });
      const data = await res.json();
      if (data.success) {
        await loadData();
      }
    } catch (err) {
      alert('Error deleting district: ' + err.message);
    }
  };

  // 2. Create Mandal
  const handleCreateMandal = async (e) => {
    e.preventDefault();
    if (!mandalNameInput.trim() || !targetDistrict) return;
    try {
      const res = await fetch(`${API_BASE}/locations/districts/${targetDistrict.id}/mandals`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ name: mandalNameInput.trim() })
      });
      const data = await res.json();
      if (data.success) {
        setShowAddMandalModal(false);
        setMandalNameInput('');
        await loadData();
      } else {
        alert(data.message || 'Error adding mandal');
      }
    } catch (err) {
      alert('Error adding mandal: ' + err.message);
    }
  };

  // Delete Mandal
  const handleDeleteMandal = async (distId, mandalId, mandalName) => {
    if (!window.confirm(`Delete Mandal "${mandalName}" and all its villages?`)) return;
    try {
      const res = await fetch(`${API_BASE}/locations/districts/${distId}/mandals/${mandalId}`, {
        method: 'DELETE'
      });
      const data = await res.json();
      if (data.success) {
        await loadData();
      }
    } catch (err) {
      alert('Error deleting mandal: ' + err.message);
    }
  };

  // 3. Create Village
  const handleCreateVillage = async (e) => {
    e.preventDefault();
    if (!villageNameInput.trim() || !targetDistrict || !targetMandal) return;
    try {
      const res = await fetch(`${API_BASE}/locations/districts/${targetDistrict.id}/mandals/${targetMandal.id}/villages`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          name: villageNameInput.trim(),
          pincode: villagePincodeInput.trim()
        })
      });
      const data = await res.json();
      if (data.success) {
        setShowAddVillageModal(false);
        setVillageNameInput('');
        setVillagePincodeInput('');
        await loadData();
      } else {
        alert(data.message || 'Error adding village');
      }
    } catch (err) {
      alert('Error adding village: ' + err.message);
    }
  };

  // Delete Village
  const handleDeleteVillage = async (distId, mandalId, villageId, villageName) => {
    if (!window.confirm(`Delete Village/Ward "${villageName}"?`)) return;
    try {
      const res = await fetch(`${API_BASE}/locations/districts/${distId}/mandals/${mandalId}/villages/${villageId}`, {
        method: 'DELETE'
      });
      const data = await res.json();
      if (data.success) {
        await loadData();
      }
    } catch (err) {
      alert('Error deleting village: ' + err.message);
    }
  };

  // ================= CUSTOMERS MANAGEMENT HANDLERS =================
  const handleCreateCustomer = async (e) => {
    e.preventDefault();
    if (!custNameInput.trim() || !custPhoneInput.trim()) return;
    try {
      const token = await getAdminToken();
      const res = await fetch(`${API_BASE}/admin/users`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          Authorization: `Bearer ${token}`
        },
        body: JSON.stringify({
          name: custNameInput.trim(),
          phone: custPhoneInput.trim(),
          email: custEmailInput.trim(),
          address: custAddressInput.trim(),
          district: custDistrictInput,
          mandal: custMandalInput,
          village: custVillageInput
        })
      });
      const data = await res.json();
      if (data.success) {
        setShowAddCustomerModal(false);
        setCustNameInput('');
        setCustPhoneInput('');
        setCustEmailInput('');
        setCustAddressInput('');
        await loadData();
      } else {
        alert(data.message || 'Error registering customer');
      }
    } catch (err) {
      alert('Error registering customer: ' + err.message);
    }
  };

  const handleDeleteCustomer = async (custId, custName) => {
    if (!window.confirm(`Delete customer profile for "${custName}"?`)) return;
    try {
      const token = await getAdminToken();
      const res = await fetch(`${API_BASE}/admin/users/${custId}`, {
        method: 'DELETE',
        headers: { Authorization: `Bearer ${token}` }
      });
      const data = await res.json();
      if (data.success) {
        await loadData();
      }
    } catch (err) {
      alert('Error deleting customer: ' + err.message);
    }
  };

  // ================= PARTNERS MANAGEMENT HANDLERS =================
  const handleCreatePartner = async (e) => {
    e.preventDefault();
    if (!partnerNameInput.trim() || !partnerPhoneInput.trim()) return;
    try {
      const token = await getAdminToken();
      const res = await fetch(`${API_BASE}/admin/providers`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          Authorization: `Bearer ${token}`
        },
        body: JSON.stringify({
          name: partnerNameInput.trim(),
          phone: partnerPhoneInput.trim(),
          email: partnerEmailInput.trim(),
          category: partnerCatInput,
          serviceName: partnerServiceNameInput.trim() || 'Verified Specialist',
          aadhaarNumber: partnerAadhaarInput.trim() || 'XXXX-XXXX-8921',
          vehicleNumber: partnerVehicleInput.trim() || ''
        })
      });
      const data = await res.json();
      if (data.success) {
        setShowAddPartnerModal(false);
        setPartnerNameInput('');
        setPartnerPhoneInput('');
        setPartnerEmailInput('');
        setPartnerServiceNameInput('');
        setPartnerAadhaarInput('');
        setPartnerVehicleInput('');
        await loadData();
      } else {
        alert(data.message || 'Error onboarding partner');
      }
    } catch (err) {
      alert('Error onboarding partner: ' + err.message);
    }
  };

  const handleDeletePartner = async (provId, provName) => {
    if (!window.confirm(`Remove service partner "${provName}" from platform?`)) return;
    try {
      const token = await getAdminToken();
      const res = await fetch(`${API_BASE}/admin/providers/${provId}`, {
        method: 'DELETE',
        headers: { Authorization: `Bearer ${token}` }
      });
      const data = await res.json();
      if (data.success) {
        await loadData();
      }
    } catch (err) {
      alert('Error removing partner: ' + err.message);
    }
  };

  const handleTogglePartnerOnline = async (provId) => {
    try {
      const token = await getAdminToken();
      const res = await fetch(`${API_BASE}/admin/providers/${provId}/toggle-online`, {
        method: 'PATCH',
        headers: { Authorization: `Bearer ${token}` }
      });
      const data = await res.json();
      if (data.success) {
        await loadData();
      }
    } catch (err) {
      alert('Error toggling partner status: ' + err.message);
    }
  };

  // KYC Approval handler
  const handleKycStatus = async (providerId, status) => {
    try {
      const token = await getAdminToken();
      const res = await fetch(`${API_BASE}/admin/providers/${providerId}/kyc`, {
        method: 'PATCH',
        headers: {
          'Content-Type': 'application/json',
          Authorization: `Bearer ${token}`
        },
        body: JSON.stringify({ status })
      });
      const data = await res.json();
      if (data.success) {
        loadData();
      }
    } catch (err) {
      alert('Error updating KYC: ' + err.message);
    }
  };

  // Subscription Status Handler
  const handleSubscriptionStatus = async (providerId, status, paymentMethod = 'cash', amount = 1499, months = 12) => {
    try {
      const token = await getAdminToken();
      const res = await fetch(`${API_BASE}/admin/providers/${providerId}/subscription`, {
        method: 'PATCH',
        headers: {
          'Content-Type': 'application/json',
          Authorization: `Bearer ${token}`
        },
        body: JSON.stringify({ status, paymentMethod, amount, months })
      });
      const data = await res.json();
      if (data.success) {
        await loadData();
      } else {
        alert('Failed to update subscription: ' + (data.message || 'Unknown error'));
      }
    } catch (err) {
      alert('Error updating subscription: ' + err.message);
    }
  };

  const handleOpenEditSubPricing = (catId, sub) => {
    setSubPricingModal({ catId, sub });
    setSub1mInput(sub.subscriptionPlans?.['1_month'] || 199);
    setSub3mInput(sub.subscriptionPlans?.['3_months'] || 499);
    setSub6mInput(sub.subscriptionPlans?.['6_months'] || 899);
    setSub1yInput(sub.subscriptionPlans?.['1_year'] || 1499);
  };

  const handleSaveSubPricing = async () => {
    if (!subPricingModal) return;
    try {
      const token = await getAdminToken();
      const res = await fetch(`${API_BASE}/categories/${subPricingModal.catId}/subcategories/${subPricingModal.sub.id}`, {
        method: 'PUT',
        headers: {
          'Content-Type': 'application/json',
          Authorization: `Bearer ${token}`
        },
        body: JSON.stringify({
          subscriptionPlans: {
            '1_month': Number(sub1mInput) || 199,
            '3_months': Number(sub3mInput) || 499,
            '6_months': Number(sub6mInput) || 899,
            '1_year': Number(sub1yInput) || 1499
          }
        })
      });
      const data = await res.json();
      if (data.success) {
        setSubPricingModal(null);
        await loadData();
      } else {
        alert('Failed to update pricing: ' + (data.message || 'Error'));
      }
    } catch (err) {
      alert('Error updating sub-category pricing: ' + err.message);
    }
  };

  const handleOpenPaySubModal = (partner) => {
    const cat = categories.find(c => c.id === partner.category);
    const sub = cat?.subCategories?.find(s => s.id === (partner.subCategoryId || partner.subCategory));
    const plans = sub?.subscriptionPlans || { '1_month': 199, '3_months': 499, '6_months': 899, '1_year': 1499 };
    setPaySubModal({ partner, cat, sub, plans });
    setPayPlanDuration('1_year');
    setPayCustomAmount(plans['1_year'] || 1499);
    setPayMethod('cash');
  };

  const handleConfirmSubscriptionPayment = async () => {
    if (!paySubModal) return;
    const { partner, plans } = paySubModal;
    let months = 12;
    let amount = plans['1_year'] || 1499;

    if (payPlanDuration === '1_month') {
      months = 1;
      amount = plans['1_month'] || 199;
    } else if (payPlanDuration === '3_months') {
      months = 3;
      amount = plans['3_months'] || 499;
    } else if (payPlanDuration === '6_months') {
      months = 6;
      amount = plans['6_months'] || 899;
    } else if (payPlanDuration === 'custom') {
      amount = Number(payCustomAmount) || 1000;
      months = 12;
    }

    await handleSubscriptionStatus(partner.id, 'active', payMethod, amount, months);
    setPaySubModal(null);
  };

  // Quick Test Dispatch simulator
  const handleQuickTestOrder = async () => {
    try {
      const token = await getAdminToken();
      const sampleServices = ['srv_1', 'srv_3', 'srv_5', 'srv_6', 'srv_8'];
      const randomSrv = sampleServices[Math.floor(Math.random() * sampleServices.length)];

      const res = await fetch(`${API_BASE}/orders`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          Authorization: `Bearer ${token}`
        },
        body: JSON.stringify({
          serviceId: randomSrv,
          customerAddress: 'Jubilee Hills Road No. 36, Hyderabad',
          paymentMethod: 'UPI / Online',
          notes: 'Emergency quick booking via Loki Admin test simulator'
        })
      });
      const data = await res.json();
      if (data.success) {
        loadData();
      }
    } catch (err) {
      alert('Error creating test order: ' + err.message);
    }
  };

  const stats = dashboardData?.stats || {
    totalRevenue: 284,
    platformEarnings: 28,
    totalOrders: 2,
    activeOrdersCount: 1,
    completedOrdersCount: 1,
    totalProviders: 4,
    onlineProviders: 3,
    pendingKycCount: 1,
    totalCustomers: 1
  };

  const getCategoryIcon = (catOrId) => {
    let cat = typeof catOrId === 'object' ? catOrId : categories.find(c => c.id === catOrId);
    if (cat?.iconUrl) {
      return (
        <img
          src={cat.iconUrl}
          alt={cat.name}
          style={{ width: 20, height: 20, objectFit: 'contain', borderRadius: 4 }}
          onError={(e) => { e.target.style.display = 'none'; }}
        />
      );
    }
    const id = typeof catOrId === 'string' ? catOrId : cat?.id;
    switch (id) {
      case 'cat_plumbing': return <Wrench size={18} color="#DE4915" />;
      case 'cat_electrical': return <Zap size={18} color="#F59E0B" />;
      case 'cat_delivery': return <Package size={18} color="#10B981" />;
      case 'cat_mechanic': return <Car size={18} color="#EF4444" />;
      case 'cat_shops': return <ShoppingBag size={18} color="#8B5CF6" />;
      case 'cat_cleaning': return <Sparkles size={18} color="#06B6D4" />;
      case 'cat_appliances': return <Tv size={18} color="#EC4899" />;
      default: return <Layers size={18} color="#DE4915" />;
    }
  };

  // 3-Column Drill-Down Hierarchy Selection state
  const selectedCat = categories.find(c => c.id === selectedCatId) || categories[0] || null;
  const currentSubCategories = selectedCat?.subCategories || [];
  const selectedSub = currentSubCategories.find(s => s.id === selectedSubId) || currentSubCategories[0] || null;
  const currentChildCategories = selectedSub?.childCategories || [];

  const handleSelectCat = (cat) => {
    setSelectedCatId(cat.id);
    setSelectedSubId(cat.subCategories?.[0]?.id || null);
  };

  const handleSelectSub = (sub) => {
    setSelectedSubId(sub.id);
  };

  // Location Hierarchy Selection state (District -> Mandal -> Village)
  const selectedDistrict = locations.find(d => d.id === selectedDistrictId) || locations[0] || null;
  const currentMandals = selectedDistrict?.mandals || [];
  const selectedMandal = currentMandals.find(m => m.id === selectedMandalId) || currentMandals[0] || null;
  const currentVillages = selectedMandal?.villages || [];

  const handleSelectDistrict = (dist) => {
    setSelectedDistrictId(dist.id);
    setSelectedMandalId(dist.mandals?.[0]?.id || null);
  };

  const handleSelectMandal = (mnd) => {
    setSelectedMandalId(mnd.id);
  };

  // Filtered lists for Customers and Partners tabs
  const filteredCustomers = customers.filter(c => {
    if (!customerSearch.trim()) return true;
    const q = customerSearch.toLowerCase();
    return (
      (c.name && c.name.toLowerCase().includes(q)) ||
      (c.phone && c.phone.toLowerCase().includes(q)) ||
      (c.email && c.email.toLowerCase().includes(q)) ||
      (c.address && c.address.toLowerCase().includes(q)) ||
      (c.village && c.village.toLowerCase().includes(q)) ||
      (c.mandal && c.mandal.toLowerCase().includes(q)) ||
      (c.district && c.district.toLowerCase().includes(q))
    );
  });

  const partnerOnlineCount = partners.filter(p => p.isOnline).length;
  const partnerPendingCount = partners.filter(p => p.kycStatus === 'pending').length;
  const partnerVerifiedCount = partners.filter(p => p.kycStatus === 'verified').length;

  const filteredPartners = partners.filter(p => {
    if (partnerFilter === 'online' && !p.isOnline) return false;
    if (partnerFilter === 'pending' && p.kycStatus !== 'pending') return false;
    if (partnerFilter === 'approved' && p.kycStatus !== 'verified') return false;

    if (!partnerSearch.trim()) return true;
    const q = partnerSearch.toLowerCase();
    return (
      (p.name && p.name.toLowerCase().includes(q)) ||
      (p.phone && p.phone.toLowerCase().includes(q)) ||
      (p.email && p.email.toLowerCase().includes(q)) ||
      (p.category && p.category.toLowerCase().includes(q)) ||
      (p.serviceName && p.serviceName.toLowerCase().includes(q))
    );
  });

  const filteredPromotions = promotions.filter(promo => {
    const matchesType = promoTypeFilter === 'all' || promo.type === promoTypeFilter;
    if (!promoSearch.trim()) return matchesType;
    const q = promoSearch.toLowerCase();
    const matchesSearch =
      (promo.title && promo.title.toLowerCase().includes(q)) ||
      (promo.storeName && promo.storeName.toLowerCase().includes(q)) ||
      (promo.offer && promo.offer.toLowerCase().includes(q)) ||
      (promo.location && promo.location.toLowerCase().includes(q));
    return matchesType && matchesSearch;
  });

  return (
    <div style={{ display: 'flex', minHeight: '100vh', background: 'var(--bg-primary)' }}>
      {/* Sidebar */}
      <aside style={{
        width: 275,
        background: '#FFFFFF',
        borderRight: '1px solid var(--border)',
        display: 'flex',
        flexDirection: 'column',
        position: 'sticky',
        top: 0,
        height: '100vh',
        zIndex: 50,
        boxShadow: '2px 0 10px rgba(0, 0, 0, 0.02)'
      }}>
        {/* Brand */}
        <div style={{ padding: '20px 18px', borderBottom: '1px solid var(--border)', display: 'flex', alignItems: 'center', gap: 12 }}>
          {/* Locki Logo Mark */}
          <div style={{
            width: 44,
            height: 44,
            borderRadius: 14,
            background: '#DE4915',
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center',
            boxShadow: '0 4px 16px rgba(222, 73, 21, 0.35)',
            flexShrink: 0
          }}>
            <svg width="28" height="28" viewBox="0 0 100 100" fill="none">
              <path d="M 50 20 L 22 43.5 C 21.2 44.2 21.8 45.5 23 45.5 H 29.5 V 74 C 29.5 75.5 30.8 76.5 32.5 76.5 H 67.5 C 69.2 76.5 70.5 75.5 70.5 74 V 45.5 H 77 C 78.2 45.5 78.8 44.2 78 43.5 Z" fill="#FFFFFF" />
              <circle cx="50" cy="58" r="8.5" fill="#DE4915" />
              <circle cx="50" cy="58" r="5" fill="#FFFFFF" />
              <circle cx="50" cy="58" r="2.8" fill="#DE4915" />
            </svg>
          </div>
          <div>
            <div style={{ display: 'flex', alignItems: 'center', gap: 2 }}>
              <span style={{ fontSize: '1.4rem', fontWeight: 800, color: '#192338', letterSpacing: '-0.02em', fontFamily: 'var(--font-heading)' }}>Lock</span>
              <span style={{ fontSize: '1.4rem', fontWeight: 800, color: '#DE4915', letterSpacing: '-0.02em', fontFamily: 'var(--font-heading)' }}>i</span>
              <span style={{ fontSize: '0.66rem', fontWeight: 700, marginLeft: 6, color: '#DE4915', background: '#FFF4EF', padding: '2px 6px', borderRadius: 6, border: '1px solid rgba(222,73,21,0.25)' }}>HQ</span>
            </div>
            <p style={{ fontSize: '0.68rem', color: 'var(--text-muted)', fontWeight: 600, marginTop: 2, letterSpacing: '0.04em' }}>SUPER ADMIN CONSOLE</p>
          </div>
        </div>

        {/* Navigation Tabs */}
        <nav style={{ padding: '16px 12px', display: 'flex', flexDirection: 'column', gap: 4, flex: 1, overflowY: 'auto' }}>
          
          {/* Section 1: CORE */}
          <div style={{ padding: '8px 10px 4px', fontSize: '0.68rem', fontWeight: 700, color: '#94A3B8', letterSpacing: '0.06em' }}>
            CORE PLATFORM
          </div>

          <button
            onClick={() => setActiveTab('overview')}
            style={{
              display: 'flex',
              alignItems: 'center',
              gap: 12,
              padding: '10px 14px',
              borderRadius: 8,
              background: activeTab === 'overview' ? '#FFF4EF' : 'transparent',
              color: activeTab === 'overview' ? '#DE4915' : '#475569',
              border: activeTab === 'overview' ? '1px solid #FFD3C2' : '1px solid transparent',
              fontWeight: activeTab === 'overview' ? 700 : 500,
              fontSize: '0.86rem',
              cursor: 'pointer',
              whiteSpace: 'nowrap',
              transition: 'all 0.15s ease'
            }}
          >
            <LayoutDashboard size={18} color={activeTab === 'overview' ? '#DE4915' : '#64748B'} />
            <span>Overview & Analytics</span>
          </button>

          {/* Section 2: CATALOG & TERRITORIES */}
          <div style={{ padding: '16px 10px 4px', fontSize: '0.68rem', fontWeight: 700, color: '#94A3B8', letterSpacing: '0.06em' }}>
            SERVICES & COVERAGE
          </div>

          <button
            onClick={() => setActiveTab('tree')}
            style={{
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'space-between',
              padding: '10px 14px',
              borderRadius: 8,
              background: activeTab === 'tree' ? '#FFF4EF' : 'transparent',
              color: activeTab === 'tree' ? '#DE4915' : '#475569',
              border: activeTab === 'tree' ? '1px solid #FFD3C2' : '1px solid transparent',
              fontWeight: activeTab === 'tree' ? 700 : 500,
              fontSize: '0.86rem',
              cursor: 'pointer',
              whiteSpace: 'nowrap',
              transition: 'all 0.15s ease'
            }}
          >
            <div style={{ display: 'flex', alignItems: 'center', gap: 12 }}>
              <FolderTree size={18} color={activeTab === 'tree' ? '#DE4915' : '#64748B'} />
              <span>Service Categories</span>
            </div>
            <span style={{
              fontSize: '0.68rem',
              fontWeight: 700,
              padding: '2px 7px',
              borderRadius: 10,
              background: activeTab === 'tree' ? '#FFD3C2' : '#F1F5F9',
              color: activeTab === 'tree' ? '#B8350B' : '#64748B'
            }}>
              {categories.length}
            </span>
          </button>

          <button
            onClick={() => setActiveTab('locations')}
            style={{
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'space-between',
              padding: '10px 14px',
              borderRadius: 8,
              background: activeTab === 'locations' ? '#FFF4EF' : 'transparent',
              color: activeTab === 'locations' ? '#DE4915' : '#475569',
              border: activeTab === 'locations' ? '1px solid #FFD3C2' : '1px solid transparent',
              fontWeight: activeTab === 'locations' ? 700 : 500,
              fontSize: '0.86rem',
              cursor: 'pointer',
              whiteSpace: 'nowrap',
              transition: 'all 0.15s ease'
            }}
          >
            <div style={{ display: 'flex', alignItems: 'center', gap: 12 }}>
              <MapPin size={18} color={activeTab === 'locations' ? '#DE4915' : '#64748B'} />
              <span>Location Management</span>
            </div>
            <span style={{
              fontSize: '0.68rem',
              fontWeight: 700,
              padding: '2px 7px',
              borderRadius: 10,
              background: activeTab === 'locations' ? '#FFD3C2' : '#F1F5F9',
              color: activeTab === 'locations' ? '#B8350B' : '#64748B'
            }}>
              {locations.length}
            </span>
          </button>

          {/* Section 3: USERS & FLEET */}
          <div style={{ padding: '16px 10px 4px', fontSize: '0.68rem', fontWeight: 700, color: '#94A3B8', letterSpacing: '0.06em' }}>
            USERS & FLEET
          </div>

          <button
            onClick={() => setActiveTab('customers')}
            style={{
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'space-between',
              padding: '10px 14px',
              borderRadius: 8,
              background: activeTab === 'customers' ? '#FFF4EF' : 'transparent',
              color: activeTab === 'customers' ? '#DE4915' : '#475569',
              border: activeTab === 'customers' ? '1px solid #FFD3C2' : '1px solid transparent',
              fontWeight: activeTab === 'customers' ? 700 : 500,
              fontSize: '0.86rem',
              cursor: 'pointer',
              whiteSpace: 'nowrap',
              transition: 'all 0.15s ease'
            }}
          >
            <div style={{ display: 'flex', alignItems: 'center', gap: 12 }}>
              <Users size={18} color={activeTab === 'customers' ? '#DE4915' : '#64748B'} />
              <span>App Customers</span>
            </div>
            <span style={{
              fontSize: '0.68rem',
              fontWeight: 700,
              padding: '2px 7px',
              borderRadius: 10,
              background: activeTab === 'customers' ? '#FFD3C2' : '#F1F5F9',
              color: activeTab === 'customers' ? '#B8350B' : '#64748B'
            }}>
              {customers.length}
            </span>
          </button>

          <button
            onClick={() => setActiveTab('partners')}
            style={{
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'space-between',
              padding: '10px 14px',
              borderRadius: 8,
              background: activeTab === 'partners' ? '#FFF4EF' : 'transparent',
              color: activeTab === 'partners' ? '#DE4915' : '#475569',
              border: activeTab === 'partners' ? '1px solid #FFD3C2' : '1px solid transparent',
              fontWeight: activeTab === 'partners' ? 700 : 500,
              fontSize: '0.86rem',
              cursor: 'pointer',
              whiteSpace: 'nowrap',
              transition: 'all 0.15s ease'
            }}
          >
            <div style={{ display: 'flex', alignItems: 'center', gap: 12 }}>
              <Briefcase size={18} color={activeTab === 'partners' ? '#DE4915' : '#64748B'} />
              <span>Service Partners</span>
            </div>
            <span style={{
              fontSize: '0.68rem',
              fontWeight: 700,
              padding: '2px 7px',
              borderRadius: 10,
              background: activeTab === 'partners' ? '#FFD3C2' : '#F1F5F9',
              color: activeTab === 'partners' ? '#B8350B' : '#64748B'
            }}>
              {partners.length}
            </span>
          </button>

          {/* Section 4: MARKETING & MONETIZATION */}
          <div style={{ padding: '16px 10px 4px', fontSize: '0.68rem', fontWeight: 700, color: '#94A3B8', letterSpacing: '0.06em' }}>
            MARKETING & MONETIZATION
          </div>

          <button
            onClick={() => setActiveTab('promotions')}
            style={{
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'space-between',
              padding: '10px 14px',
              borderRadius: 8,
              background: activeTab === 'promotions' ? '#FFF4EF' : 'transparent',
              color: activeTab === 'promotions' ? '#DE4915' : '#475569',
              border: activeTab === 'promotions' ? '1px solid #FFD3C2' : '1px solid transparent',
              fontWeight: activeTab === 'promotions' ? 700 : 500,
              fontSize: '0.86rem',
              cursor: 'pointer',
              whiteSpace: 'nowrap',
              transition: 'all 0.15s ease'
            }}
          >
            <div style={{ display: 'flex', alignItems: 'center', gap: 12 }}>
              <Megaphone size={18} color={activeTab === 'promotions' ? '#DE4915' : '#64748B'} />
              <span>Ads & Promotions</span>
            </div>
            <span style={{
              fontSize: '0.68rem',
              fontWeight: 700,
              padding: '2px 7px',
              borderRadius: 10,
              background: activeTab === 'promotions' ? '#FFD3C2' : '#F1F5F9',
              color: activeTab === 'promotions' ? '#B8350B' : '#64748B'
            }}>
              {promotions.filter(p => p.active).length} Active
            </span>
          </button>
        </nav>

        {/* Server Status Badge at bottom */}
        <div style={{ padding: '16px 20px', borderTop: '1px solid var(--border)', background: '#F8FAFC' }}>
          <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
            <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
              <div className="pulse-dot" style={{ background: serverOnline ? '#10B981' : '#EF4444' }} />
              <span style={{ fontSize: '0.75rem', color: serverOnline ? '#059669' : '#DC2626', fontWeight: 600 }}>
                {serverOnline ? 'API GATEWAY 5000' : 'OFFLINE'}
              </span>
            </div>
            <button
              onClick={loadData}
              title="Refresh"
              style={{ background: 'none', color: 'var(--text-muted)', cursor: 'pointer' }}
            >
              <RefreshCw size={14} />
            </button>
          </div>
        </div>
      </aside>

      {/* Main Content Area */}
      <main style={{ flex: 1, display: 'flex', flexDirection: 'column', overflowY: 'auto' }}>
        {/* Top Header */}
        <header style={{
          padding: '18px 32px',
          borderBottom: '1px solid var(--border)',
          background: 'rgba(255, 255, 255, 0.95)',
          backdropFilter: 'blur(12px)',
          display: 'flex',
          justifyContent: 'space-between',
          alignItems: 'center',
          position: 'sticky',
          top: 0,
          zIndex: 40
        }}>
          <div>
            <h1 style={{ fontSize: '1.4rem', fontWeight: 700, color: '#192338' }}>
              {activeTab === 'overview'
                ? 'Executive Overview'
                : activeTab === 'promotions'
                ? 'Ads & Promotions Manager'
                : activeTab === 'locations'
                ? 'Location & Territory Management'
                : activeTab === 'customers'
                ? 'Customers Management'
                : activeTab === 'partners'
                ? 'Service Partners Fleet'
                : 'Service Tree Management'}
            </h1>
            <p style={{ fontSize: '0.8rem', color: 'var(--text-muted)' }}>
              {activeTab === 'overview'
                ? 'Real-Time GMV, Active Fleet, KYC Queue & Verticals Performance'
                : activeTab === 'promotions'
                ? 'Manage Top Carousel Banners, Local Spotlight Billboards, Sponsored Deals & Login Popups'
                : activeTab === 'locations'
                ? 'District ➔ Mandal ➔ Village / Ward Coverage System'
                : activeTab === 'customers'
                ? 'Registered App Customers, Territory & Active Orders'
                : activeTab === 'partners'
                ? 'Partner App Registrations, KYC Verifications & Live Fleet'
                : 'Category ➔ Sub-Category ➔ Child-Category Setup'}
            </p>
          </div>

          <div style={{ display: 'flex', alignItems: 'center', gap: 14 }}>
            {activeTab === 'promotions' ? (
              <button
                onClick={() => {
                  resetPromoForm();
                  setShowPromoModal(true);
                }}
                style={{
                  display: 'flex',
                  alignItems: 'center',
                  gap: 8,
                  background: 'linear-gradient(135deg, #DE4915 0%, #B8350B 100%)',
                  color: '#fff',
                  padding: '9px 18px',
                  borderRadius: 'var(--radius-sm)',
                  fontWeight: 600,
                  fontSize: '0.85rem',
                  boxShadow: '0 4px 14px rgba(222, 73, 21, 0.3)',
                  cursor: 'pointer'
                }}
              >
                <Plus size={16} /> Create New Ad / Banner
              </button>
            ) : activeTab === 'tree' ? (
              <button
                onClick={handleOpenAddCategory}
                style={{
                  display: 'flex',
                  alignItems: 'center',
                  gap: 8,
                  background: 'linear-gradient(135deg, #DE4915 0%, #B8350B 100%)',
                  color: '#fff',
                  padding: '9px 18px',
                  borderRadius: 'var(--radius-sm)',
                  fontWeight: 600,
                  fontSize: '0.85rem',
                  boxShadow: '0 4px 14px rgba(222, 73, 21, 0.3)',
                  cursor: 'pointer'
                }}
              >
                <Plus size={16} /> Add Category
              </button>
            ) : activeTab === 'locations' ? (
              <button
                onClick={() => setShowAddDistrictModal(true)}
                style={{
                  display: 'flex',
                  alignItems: 'center',
                  gap: 8,
                  background: 'linear-gradient(135deg, #DE4915 0%, #B8350B 100%)',
                  color: '#fff',
                  padding: '9px 18px',
                  borderRadius: 'var(--radius-sm)',
                  fontWeight: 600,
                  fontSize: '0.85rem',
                  boxShadow: '0 4px 14px rgba(222, 73, 21, 0.3)',
                  cursor: 'pointer'
                }}
              >
                <Plus size={16} /> Add District
              </button>
            ) : activeTab === 'customers' ? (
              <button
                onClick={() => setShowAddCustomerModal(true)}
                style={{
                  display: 'flex',
                  alignItems: 'center',
                  gap: 8,
                  background: 'linear-gradient(135deg, #DE4915 0%, #B8350B 100%)',
                  color: '#fff',
                  padding: '9px 18px',
                  borderRadius: 'var(--radius-sm)',
                  fontWeight: 600,
                  fontSize: '0.85rem',
                  boxShadow: '0 4px 14px rgba(222, 73, 21, 0.3)',
                  cursor: 'pointer'
                }}
              >
                <Plus size={16} /> Add Customer
              </button>
            ) : activeTab === 'partners' ? (
              <button
                onClick={() => setShowAddPartnerModal(true)}
                style={{
                  display: 'flex',
                  alignItems: 'center',
                  gap: 8,
                  background: 'linear-gradient(135deg, #DE4915 0%, #B8350B 100%)',
                  color: '#fff',
                  padding: '9px 18px',
                  borderRadius: 'var(--radius-sm)',
                  fontWeight: 600,
                  fontSize: '0.85rem',
                  boxShadow: '0 4px 14px rgba(222, 73, 21, 0.3)',
                  cursor: 'pointer'
                }}
              >
                <Plus size={16} /> Add Partner
              </button>
            ) : (
              <button
                onClick={handleQuickTestOrder}
                style={{
                  display: 'flex',
                  alignItems: 'center',
                  gap: 8,
                  background: 'linear-gradient(135deg, #10B981 0%, #059669 100%)',
                  color: '#fff',
                  padding: '9px 16px',
                  borderRadius: 'var(--radius-sm)',
                  fontWeight: 600,
                  fontSize: '0.85rem',
                  boxShadow: '0 4px 12px rgba(16, 185, 129, 0.25)',
                  cursor: 'pointer'
                }}
              >
                <Zap size={16} /> Simulate Test Customer Order
              </button>
            )}

            <div style={{
              display: 'flex',
              alignItems: 'center',
              gap: 10,
              padding: '6px 14px',
              borderRadius: 'var(--radius-sm)',
              background: '#F8FAFC',
              border: '1px solid var(--border)'
            }}>
              <div style={{ width: 30, height: 30, borderRadius: '50%', background: '#DE4915', display: 'flex', alignItems: 'center', justifyContent: 'center', color: '#fff', fontWeight: 700, fontSize: '0.85rem' }}>
                A
              </div>
              <div>
                <p style={{ fontSize: '0.8rem', fontWeight: 600, color: '#192338' }}>Admin Prasad</p>
                <p style={{ fontSize: '0.68rem', color: '#DE4915', fontWeight: 600 }}>Super Admin</p>
              </div>
            </div>
          </div>
        </header>

        {/* Body Container */}
        <div style={{ padding: '28px 32px', display: 'flex', flexDirection: 'column', gap: 24 }}>
          
          {/* TAB 1: OVERVIEW */}
          {activeTab === 'overview' && (
            <>
              {/* Metric KPI Cards */}
              <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(230px, 1fr))', gap: 20 }}>
                {/* Total GMV */}
                <div className="glass-panel" style={{ padding: '22px' }}>
                  <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start' }}>
                    <p style={{ fontSize: '0.82rem', color: 'var(--text-muted)', fontWeight: 600 }}>PLATFORM GMV</p>
                    <div style={{ width: 36, height: 36, borderRadius: 10, background: '#FFF4EF', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
                      <TrendingUp size={19} color="#DE4915" />
                    </div>
                  </div>
                  <h3 style={{ fontSize: '1.8rem', fontWeight: 800, marginTop: 10, color: 'var(--text-main)' }}>
                    ₹{stats.totalRevenue.toLocaleString()}
                  </h3>
                  <div style={{ display: 'flex', alignItems: 'center', gap: 6, marginTop: 8, fontSize: '0.75rem', color: '#059669', fontWeight: 600 }}>
                    <ArrowUpRight size={14} /> +18.4% this week
                  </div>
                </div>

                {/* Platform Commission (10%) */}
                <div className="glass-panel" style={{ padding: '22px' }}>
                  <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start' }}>
                    <p style={{ fontSize: '0.82rem', color: 'var(--text-muted)', fontWeight: 600 }}>LOCKI COMMISSION (10%)</p>
                    <div style={{ width: 36, height: 36, borderRadius: 10, background: '#FFFBEB', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
                      <DollarSign size={19} color="#D97706" />
                    </div>
                  </div>
                  <h3 style={{ fontSize: '1.8rem', fontWeight: 800, marginTop: 10, color: '#D97706' }}>
                    ₹{stats.platformEarnings.toLocaleString()}
                  </h3>
                  <p style={{ fontSize: '0.75rem', color: 'var(--text-muted)', marginTop: 8 }}>
                    Net platform revenue
                  </p>
                </div>

                {/* Active Orders */}
                <div className="glass-panel" style={{ padding: '22px' }}>
                  <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start' }}>
                    <p style={{ fontSize: '0.82rem', color: 'var(--text-muted)', fontWeight: 600 }}>ACTIVE LIVE ORDERS</p>
                    <div style={{ width: 36, height: 36, borderRadius: 10, background: '#ECFDF5', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
                      <Radio size={19} color="#059669" />
                    </div>
                  </div>
                  <h3 style={{ fontSize: '1.8rem', fontWeight: 800, marginTop: 10, color: '#059669' }}>
                    {stats.activeOrdersCount}
                  </h3>
                  <p style={{ fontSize: '0.75rem', color: 'var(--text-muted)', marginTop: 8 }}>
                    In progress & dispatched
                  </p>
                </div>

                {/* Partner Fleet */}
                <div className="glass-panel" style={{ padding: '22px' }}>
                  <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start' }}>
                    <p style={{ fontSize: '0.82rem', color: 'var(--text-muted)', fontWeight: 600 }}>ONLINE FLEET</p>
                    <div style={{ width: 36, height: 36, borderRadius: 10, background: '#F5F3FF', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
                      <ShieldCheck size={19} color="#7C3AED" />
                    </div>
                  </div>
                  <h3 style={{ fontSize: '1.8rem', fontWeight: 800, marginTop: 10, color: '#7C3AED' }}>
                    {stats.onlineProviders} / {stats.totalProviders}
                  </h3>
                  <div style={{ display: 'flex', alignItems: 'center', gap: 6, marginTop: 8, fontSize: '0.75rem', color: '#DC2626', fontWeight: 600 }}>
                    {stats.pendingKycCount} partner KYC pending
                  </div>
                </div>
              </div>

              {/* Categories & Revenue Grid */}
              <div style={{ display: 'grid', gridTemplateColumns: '2fr 1.2fr', gap: 24 }}>
                <div className="glass-panel" style={{ padding: '24px' }}>
                  <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 16 }}>
                    <h3 style={{ fontSize: '1.1rem', fontWeight: 700, color: 'var(--text-main)' }}>
                      Hyperlocal Service Verticals Performance
                    </h3>
                    <button
                      onClick={() => setActiveTab('tree')}
                      style={{ background: 'transparent', color: '#DE4915', fontSize: '0.82rem', fontWeight: 600, cursor: 'pointer' }}
                    >
                      Manage Hierarchy Tree →
                    </button>
                  </div>
                  <div style={{ display: 'flex', flexDirection: 'column', gap: 14 }}>
                    {(dashboardData?.categoryStats || []).map(cat => (
                      <div key={cat.id} style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', padding: '12px 14px', borderRadius: 'var(--radius-sm)', background: '#F8FAFC', border: '1px solid var(--border)' }}>
                        <div style={{ display: 'flex', alignItems: 'center', gap: 12 }}>
                          <div style={{ width: 36, height: 36, borderRadius: 8, background: '#FFFFFF', border: '1px solid var(--border)', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
                            {getCategoryIcon(cat.id)}
                          </div>
                          <div>
                            <p style={{ fontWeight: 600, fontSize: '0.9rem', color: 'var(--text-main)' }}>{cat.name}</p>
                            <p style={{ fontSize: '0.75rem', color: 'var(--text-muted)' }}>
                              {cat.providersCount} Providers Active
                            </p>
                          </div>
                        </div>

                        <div style={{ textAlign: 'right' }}>
                          <p style={{ fontWeight: 700, fontSize: '0.95rem', color: 'var(--text-main)' }}>₹{cat.revenue}</p>
                          <p style={{ fontSize: '0.75rem', color: '#DE4915', fontWeight: 600 }}>{cat.totalOrders} Orders</p>
                        </div>
                      </div>
                    ))}
                  </div>
                </div>

                {/* KYC Alerts and Quick Actions */}
                <div className="glass-panel" style={{ padding: '24px', display: 'flex', flexDirection: 'column', gap: 16 }}>
                  <h3 style={{ fontSize: '1.1rem', fontWeight: 700, color: 'var(--text-main)' }}>
                    KYC Verification Queue
                  </h3>
                  {partners.filter(p => p.kycStatus === 'pending').length === 0 ? (
                    <div style={{ padding: '30px 20px', textAlign: 'center', color: 'var(--text-muted)' }}>
                      <CheckCircle2 size={36} color="#059669" style={{ margin: '0 auto 10px auto' }} />
                      <p style={{ fontWeight: 600, color: 'var(--text-main)' }}>All Partner KYC Verifications Cleared!</p>
                    </div>
                  ) : (
                    partners.filter(p => p.kycStatus === 'pending').map(p => (
                      <div key={p.id} style={{ padding: '14px', borderRadius: 'var(--radius-sm)', background: '#FFFBEB', border: '1px solid #FDE68A' }}>
                        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start' }}>
                          <div>
                            <p style={{ fontWeight: 700, color: 'var(--text-main)', fontSize: '0.92rem' }}>{p.name}</p>
                            <p style={{ fontSize: '0.78rem', color: '#D97706', fontWeight: 600 }}>{p.serviceName}</p>
                            <p style={{ fontSize: '0.72rem', color: 'var(--text-muted)', marginTop: 4 }}>
                              Aadhaar: {p.aadhaarNumber} • {p.phone}
                            </p>
                          </div>
                        </div>
                        <div style={{ display: 'flex', gap: 8, marginTop: 12 }}>
                          <button
                            onClick={() => handleKycStatus(p.id, 'approved')}
                            style={{
                              flex: 1,
                              background: '#059669',
                              color: '#fff',
                              padding: '6px 12px',
                              borderRadius: 6,
                              fontWeight: 600,
                              fontSize: '0.78rem',
                              cursor: 'pointer'
                            }}
                          >
                            Approve
                          </button>
                          <button
                            onClick={() => handleKycStatus(p.id, 'rejected')}
                            style={{
                              flex: 1,
                              background: '#FEF2F2',
                              color: '#DC2626',
                              border: '1px solid #FECACA',
                              padding: '6px 12px',
                              borderRadius: 6,
                              fontWeight: 600,
                              fontSize: '0.78rem',
                              cursor: 'pointer'
                            }}
                          >
                            Reject
                          </button>
                        </div>
                      </div>
                    ))
                  )}

                  <div style={{ marginTop: 'auto', borderTop: '1px solid var(--border)', paddingTop: 16 }}>
                    <p style={{ fontSize: '0.8rem', color: 'var(--text-muted)' }}>
                      🔒 <strong>Security Note:</strong> Unapproved partners are barred from receiving orders until Aadhaar & background check are verified.
                    </p>
                  </div>
                </div>
              </div>
            </>
          )}

          {/* TAB 2: 3-COLUMN SEPARATED HIERARCHY SYSTEM */}
          {activeTab === 'tree' && (
            <div style={{ display: 'flex', flexDirection: 'column', gap: 20 }}>
              
              {/* Interactive Breadcrumb Path Bar */}
              <div className="glass-panel" style={{
                padding: '14px 22px',
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'space-between',
                flexWrap: 'wrap',
                gap: 12
              }}>
                <div style={{ display: 'flex', alignItems: 'center', gap: 10, fontSize: '0.9rem', flexWrap: 'wrap' }}>
                  <span style={{ color: 'var(--text-muted)', display: 'flex', alignItems: 'center', gap: 6, fontWeight: 600 }}>
                    <FolderTree size={17} color="#DE4915" /> All Verticals ({categories.length})
                  </span>
                  <ChevronRight size={15} color="var(--text-dim)" />
                  <span style={{
                    fontWeight: 700,
                    background: selectedCat ? '#FFF4EF' : 'transparent',
                    color: selectedCat ? '#DE4915' : 'var(--text-dim)',
                    padding: '4px 12px',
                    borderRadius: 8,
                    border: selectedCat ? '1px solid rgba(222, 73, 21, 0.35)' : 'none',
                    display: 'flex',
                    alignItems: 'center',
                    gap: 6
                  }}>
                    {selectedCat ? (
                      <>
                        {getCategoryIcon(selectedCat.id)}
                        {selectedCat.name}
                      </>
                    ) : 'Select Category'}
                  </span>
                  <ChevronRight size={15} color="var(--text-dim)" />
                  <span style={{
                    fontWeight: 700,
                    background: selectedSub ? '#FFFBEB' : 'transparent',
                    color: selectedSub ? '#D97706' : 'var(--text-dim)',
                    padding: '4px 12px',
                    borderRadius: 8,
                    border: selectedSub ? '1px solid #FDE68A' : 'none',
                    display: 'flex',
                    alignItems: 'center',
                    gap: 6
                  }}>
                    <Tag size={14} />
                    {selectedSub?.name || 'Select Sub-Category'}
                  </span>
                </div>

                <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
                  <span style={{ fontSize: '0.78rem', color: 'var(--text-muted)', background: '#F1F5F9', border: '1px solid var(--border)', padding: '4px 10px', borderRadius: 20 }}>
                    Active Services: <strong>{currentChildCategories.length}</strong>
                  </span>
                </div>
              </div>

              {/* 3-Column Drill-Down Grid */}
              <div style={{
                display: 'grid',
                gridTemplateColumns: 'minmax(280px, 1fr) minmax(300px, 1.05fr) minmax(360px, 1.25fr)',
                gap: 20,
                alignItems: 'start'
              }}>
                
                {/* ================= COLUMN 1: CATEGORIES ================= */}
                <div className="glass-panel" style={{ display: 'flex', flexDirection: 'column', minHeight: 640 }}>
                  {/* Column 1 Header */}
                  <div style={{ padding: '16px 18px', borderBottom: '1px solid var(--border)', display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
                    <div>
                      <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
                        <span style={{ width: 8, height: 8, borderRadius: '50%', background: '#DE4915' }} />
                        <h3 style={{ fontSize: '1rem', fontWeight: 700, color: 'var(--text-main)' }}>1. Categories</h3>
                        <span className="badge" style={{ background: '#FFF4EF', color: '#DE4915', border: '1px solid rgba(222, 73, 21, 0.25)', padding: '2px 7px', fontSize: '0.7rem' }}>
                          {categories.length}
                        </span>
                      </div>
                      <p style={{ fontSize: '0.72rem', color: 'var(--text-muted)', marginTop: 2 }}>Click to explore sub-categories</p>
                    </div>

                    <button
                      onClick={handleOpenAddCategory}
                      style={{
                        display: 'flex',
                        alignItems: 'center',
                        gap: 4,
                        background: 'linear-gradient(135deg, #DE4915 0%, #B8350B 100%)',
                        color: '#fff',
                        padding: '6px 12px',
                        borderRadius: 6,
                        fontWeight: 600,
                        fontSize: '0.78rem',
                        boxShadow: '0 2px 8px rgba(222, 73, 21, 0.25)',
                        cursor: 'pointer'
                      }}
                    >
                      <Plus size={14} /> New
                    </button>
                  </div>

                  {/* Column 1 List */}
                  <div style={{ padding: 12, display: 'flex', flexDirection: 'column', gap: 8, maxHeight: 580, overflowY: 'auto' }}>
                    {categories.length === 0 ? (
                      <div style={{ padding: 40, textAlign: 'center', color: 'var(--text-muted)' }}>
                        <p style={{ fontSize: '0.85rem' }}>No categories created yet.</p>
                      </div>
                    ) : (
                      categories.map(cat => {
                        const isSelected = selectedCat?.id === cat.id;
                        return (
                          <div
                            key={cat.id}
                            onClick={() => handleSelectCat(cat)}
                            style={{
                              padding: '12px 14px',
                              borderRadius: 10,
                              cursor: 'pointer',
                              display: 'flex',
                              alignItems: 'center',
                              justifyContent: 'space-between',
                              transition: 'all 0.18s ease',
                              background: isSelected
                                ? '#FFF4EF'
                                : '#F8FAFC',
                              border: isSelected
                                ? '1.5px solid #DE4915'
                                : '1px solid var(--border)',
                              boxShadow: isSelected ? '0 2px 10px rgba(222, 73, 21, 0.15)' : 'none'
                            }}
                          >
                            <div style={{ display: 'flex', alignItems: 'center', gap: 10, flex: 1, minWidth: 0 }}>
                              <div style={{
                                width: 34,
                                height: 34,
                                borderRadius: 8,
                                background: cat.iconUrl ? '#FFFFFF' : (isSelected ? (cat.color || '#DE4915') : '#FFFFFF'),
                                border: isSelected ? '1.5px solid #DE4915' : '1px solid var(--border)',
                                display: 'flex',
                                alignItems: 'center',
                                justifyContent: 'center',
                                flexShrink: 0,
                                overflow: 'hidden'
                              }}>
                                {cat.iconUrl ? (
                                  <img src={cat.iconUrl} alt={cat.name} style={{ width: 22, height: 22, objectFit: 'contain' }} onError={(e) => { e.target.style.display = 'none'; }} />
                                ) : isSelected ? (
                                  <Layers size={17} color="#fff" />
                                ) : (
                                  getCategoryIcon(cat)
                                )}
                              </div>
                              <div style={{ overflow: 'hidden' }}>
                                <p style={{ fontWeight: 700, fontSize: '0.88rem', color: isSelected ? '#DE4915' : 'var(--text-main)', whiteSpace: 'nowrap', textOverflow: 'ellipsis', overflow: 'hidden' }}>
                                  {cat.name}
                                </p>
                                <p style={{ fontSize: '0.72rem', color: isSelected ? '#DE4915' : 'var(--text-muted)' }}>
                                  {cat.subCategories?.length || 0} Sub-categories
                                </p>
                              </div>
                            </div>

                            <div style={{ display: 'flex', alignItems: 'center', gap: 6 }}>
                              <button
                                onClick={(e) => {
                                  e.stopPropagation();
                                  handleOpenEditCategory(cat);
                                }}
                                title="Edit Category & Icon"
                                style={{
                                  background: '#F8FAFC',
                                  border: '1px solid #E2E8F0',
                                  color: 'var(--text-dim)',
                                  width: 26,
                                  height: 26,
                                  display: 'flex',
                                  alignItems: 'center',
                                  justifyContent: 'center',
                                  borderRadius: 5,
                                  cursor: 'pointer'
                                }}
                                onMouseEnter={(e) => {
                                  e.currentTarget.style.color = '#DE4915';
                                  e.currentTarget.style.borderColor = '#FDBA74';
                                  e.currentTarget.style.background = '#FFF7ED';
                                }}
                                onMouseLeave={(e) => {
                                  e.currentTarget.style.color = 'var(--text-dim)';
                                  e.currentTarget.style.borderColor = '#E2E8F0';
                                  e.currentTarget.style.background = '#F8FAFC';
                                }}
                              >
                                <Edit size={12} />
                              </button>
                              <button
                                onClick={(e) => {
                                  e.stopPropagation();
                                  handleDeleteCategory(cat.id, cat.name);
                                }}
                                title="Delete Category"
                                style={{
                                  background: '#F8FAFC',
                                  border: '1px solid #E2E8F0',
                                  color: 'var(--text-dim)',
                                  width: 26,
                                  height: 26,
                                  display: 'flex',
                                  alignItems: 'center',
                                  justifyContent: 'center',
                                  borderRadius: 5,
                                  cursor: 'pointer'
                                }}
                                onMouseEnter={(e) => {
                                  e.currentTarget.style.color = '#EF4444';
                                  e.currentTarget.style.borderColor = '#FECACA';
                                  e.currentTarget.style.background = '#FEF2F2';
                                }}
                                onMouseLeave={(e) => {
                                  e.currentTarget.style.color = 'var(--text-dim)';
                                  e.currentTarget.style.borderColor = '#E2E8F0';
                                  e.currentTarget.style.background = '#F8FAFC';
                                }}
                              >
                                <Trash2 size={12} />
                              </button>
                              <ChevronRight size={16} color={isSelected ? '#DE4915' : 'var(--text-dim)'} />
                            </div>
                          </div>
                        );
                      })
                    )}
                  </div>
                </div>

                {/* ================= COLUMN 2: SUB-CATEGORIES ================= */}
                <div className="glass-panel" style={{ display: 'flex', flexDirection: 'column', minHeight: 640 }}>
                  {/* Column 2 Header */}
                  <div style={{ padding: '16px 18px', borderBottom: '1px solid var(--border)', display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
                    <div>
                      <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
                        <span style={{ width: 8, height: 8, borderRadius: '50%', background: '#F59E0B' }} />
                        <h3 style={{ fontSize: '1rem', fontWeight: 700, color: 'var(--text-main)' }}>2. Sub-Categories</h3>
                        <span className="badge" style={{ background: '#FFFBEB', color: '#D97706', border: '1px solid #FDE68A', padding: '2px 7px', fontSize: '0.7rem' }}>
                          {currentSubCategories.length}
                        </span>
                      </div>
                      <p style={{ fontSize: '0.72rem', color: '#DE4915', marginTop: 2, fontWeight: 600 }}>
                        {selectedCat ? `In: ${selectedCat.name}` : 'No category selected'}
                      </p>
                    </div>

                    <button
                      disabled={!selectedCat}
                      onClick={() => {
                        setTargetCat(selectedCat);
                        setShowAddSubModal(true);
                      }}
                      style={{
                        display: 'flex',
                        alignItems: 'center',
                        gap: 4,
                        background: selectedCat ? '#FFFBEB' : '#F1F5F9',
                        border: selectedCat ? '1px solid #FDE68A' : '1px solid var(--border)',
                        color: selectedCat ? '#D97706' : 'var(--text-dim)',
                        padding: '6px 12px',
                        borderRadius: 6,
                        fontWeight: 600,
                        fontSize: '0.78rem',
                        cursor: selectedCat ? 'pointer' : 'not-allowed'
                      }}
                    >
                      <Plus size={14} /> Add Sub
                    </button>
                  </div>

                  {/* Column 2 List */}
                  <div style={{ padding: 12, display: 'flex', flexDirection: 'column', gap: 8, maxHeight: 580, overflowY: 'auto' }}>
                    {!selectedCat ? (
                      <div style={{ padding: 40, textAlign: 'center', color: 'var(--text-muted)' }}>
                        <p style={{ fontSize: '0.85rem' }}>Select a category on the left first.</p>
                      </div>
                    ) : currentSubCategories.length === 0 ? (
                      <div style={{ padding: 40, textAlign: 'center', color: 'var(--text-muted)' }}>
                        <p style={{ fontSize: '0.85rem', marginBottom: 12 }}>No sub-categories yet under <strong>{selectedCat.name}</strong>.</p>
                        <button
                          onClick={() => {
                            setTargetCat(selectedCat);
                            setShowAddSubModal(true);
                          }}
                          style={{
                            background: '#FFFBEB',
                            border: '1px solid #FDE68A',
                            color: '#D97706',
                            padding: '6px 14px',
                            borderRadius: 6,
                            fontSize: '0.8rem',
                            fontWeight: 600,
                            cursor: 'pointer'
                          }}
                        >
                          + Add First Sub-Category
                        </button>
                      </div>
                    ) : (
                      currentSubCategories.map(sub => {
                        const isSelected = selectedSub?.id === sub.id;
                        return (
                          <div
                            key={sub.id}
                            onClick={() => handleSelectSub(sub)}
                            style={{
                              padding: '12px 14px',
                              borderRadius: 12,
                              cursor: 'pointer',
                              display: 'flex',
                              flexDirection: 'column',
                              gap: 10,
                              transition: 'all 0.18s ease',
                              background: isSelected ? '#FFFBEB' : '#FFFFFF',
                              border: isSelected ? '1.5px solid #F59E0B' : '1px solid var(--border)',
                              boxShadow: isSelected ? '0 4px 14px rgba(245, 158, 11, 0.12)' : '0 1px 3px rgba(0,0,0,0.02)'
                            }}
                          >
                            {/* TOP ROW: Icon + Name + Tasks Count + Actions (Plans, Delete, Chevron) */}
                            <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', gap: 10 }}>
                              <div style={{ display: 'flex', alignItems: 'center', gap: 10, minWidth: 0, flex: 1 }}>
                                <div style={{
                                  width: 32,
                                  height: 32,
                                  borderRadius: 8,
                                  background: isSelected ? '#FEF3C7' : '#F1F5F9',
                                  display: 'flex',
                                  alignItems: 'center',
                                  justifyContent: 'center',
                                  flexShrink: 0
                                }}>
                                  <Folder size={16} color={isSelected ? '#D97706' : '#64748B'} />
                                </div>
                                <div style={{ minWidth: 0, overflow: 'hidden' }}>
                                  <p style={{
                                    fontWeight: 700,
                                    fontSize: '0.9rem',
                                    color: isSelected ? '#92400E' : 'var(--text-main)',
                                    whiteSpace: 'nowrap',
                                    textOverflow: 'ellipsis',
                                    overflow: 'hidden',
                                    margin: 0
                                  }}>
                                    {sub.name}
                                  </p>
                                  <span style={{ fontSize: '0.72rem', color: isSelected ? '#D97706' : 'var(--text-muted)', fontWeight: 500 }}>
                                    {sub.childCategories?.length || 0} Child Tasks
                                  </span>
                                </div>
                              </div>

                              {/* Perfectly Aligned Action Buttons Group */}
                              <div style={{ display: 'flex', alignItems: 'center', gap: 6, flexShrink: 0 }}>
                                <button
                                  onClick={(e) => {
                                    e.stopPropagation();
                                    handleOpenEditSubPricing(selectedCat.id, sub);
                                  }}
                                  title="Edit Subscription Pricing"
                                  style={{
                                    display: 'inline-flex',
                                    alignItems: 'center',
                                    gap: 4,
                                    background: isSelected ? '#FEF3C7' : '#FFFBEB',
                                    border: '1px solid #FCD34D',
                                    color: '#B45309',
                                    padding: '5px 9px',
                                    borderRadius: 6,
                                    fontSize: '0.73rem',
                                    fontWeight: 700,
                                    cursor: 'pointer',
                                    transition: 'all 0.15s ease'
                                  }}
                                  onMouseEnter={(e) => e.currentTarget.style.background = '#FDE68A'}
                                  onMouseLeave={(e) => e.currentTarget.style.background = isSelected ? '#FEF3C7' : '#FFFBEB'}
                                >
                                  <span>✏️</span> Plans
                                </button>
                                <button
                                  onClick={(e) => {
                                    e.stopPropagation();
                                    handleDeleteSubCategory(selectedCat.id, sub.id, sub.name);
                                  }}
                                  title="Delete Sub-Category"
                                  style={{
                                    display: 'inline-flex',
                                    alignItems: 'center',
                                    justifyContent: 'center',
                                    width: 28,
                                    height: 28,
                                    background: '#F8FAFC',
                                    border: '1px solid #E2E8F0',
                                    color: '#64748B',
                                    borderRadius: 6,
                                    cursor: 'pointer',
                                    transition: 'all 0.15s ease'
                                  }}
                                  onMouseEnter={(e) => {
                                    e.currentTarget.style.color = '#EF4444';
                                    e.currentTarget.style.borderColor = '#FECACA';
                                    e.currentTarget.style.background = '#FEF2F2';
                                  }}
                                  onMouseLeave={(e) => {
                                    e.currentTarget.style.color = '#64748B';
                                    e.currentTarget.style.borderColor = '#E2E8F0';
                                    e.currentTarget.style.background = '#F8FAFC';
                                  }}
                                >
                                  <Trash2 size={13} />
                                </button>
                                <div style={{
                                  display: 'inline-flex',
                                  alignItems: 'center',
                                  justifyContent: 'center',
                                  width: 20,
                                  height: 28,
                                  color: isSelected ? '#F59E0B' : '#94A3B8'
                                }}>
                                  <ChevronRight size={17} />
                                </div>
                              </div>
                            </div>

                            {/* BOTTOM ROW: Clean Subscription Pricing Pills */}
                            <div style={{
                              display: 'flex',
                              alignItems: 'center',
                              gap: 5,
                              flexWrap: 'wrap',
                              paddingTop: 8,
                              borderTop: isSelected ? '1px dashed #FDE68A' : '1px dashed #E2E8F0'
                            }}>
                              <span style={{ fontSize: '0.68rem', fontWeight: 700, color: isSelected ? '#B45309' : '#64748B', marginRight: 2 }}>
                                💳 Rates:
                              </span>
                              {[
                                { label: '1M', val: sub.subscriptionPlans?.['1_month'] || 199 },
                                { label: '3M', val: sub.subscriptionPlans?.['3_months'] || 499 },
                                { label: '6M', val: sub.subscriptionPlans?.['6_months'] || 899 },
                                { label: '1Y', val: sub.subscriptionPlans?.['1_year'] || 1499, highlight: true }
                              ].map(p => (
                                <span
                                  key={p.label}
                                  style={{
                                    fontSize: '0.67rem',
                                    padding: '2px 6px',
                                    borderRadius: 4,
                                    fontWeight: 700,
                                    background: p.highlight
                                      ? (isSelected ? '#FDE68A' : '#EFF6FF')
                                      : (isSelected ? '#FEF3C7' : '#F1F5F9'),
                                    color: p.highlight
                                      ? (isSelected ? '#92400E' : '#1D4ED8')
                                      : (isSelected ? '#B45309' : '#475569'),
                                    border: p.highlight
                                      ? (isSelected ? '1px solid #FCD34D' : '1px solid #BFDBFE')
                                      : '1px solid transparent'
                                  }}
                                >
                                  {p.label}: ₹{p.val}
                                </span>
                              ))}
                            </div>
                          </div>
                        );
                      })
                    )}
                  </div>
                </div>

                {/* ================= COLUMN 3: CHILD SERVICES & PRICING ================= */}
                <div className="glass-panel" style={{ display: 'flex', flexDirection: 'column', minHeight: 640 }}>
                  {/* Column 3 Header */}
                  <div style={{ padding: '16px 18px', borderBottom: '1px solid var(--border)', display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
                    <div>
                      <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
                        <span style={{ width: 8, height: 8, borderRadius: '50%', background: '#10B981' }} />
                        <h3 style={{ fontSize: '1rem', fontWeight: 700, color: 'var(--text-main)' }}>3. Child Services</h3>
                        <span className="badge" style={{ background: '#ECFDF5', color: '#059669', border: '1px solid #A7F3D0', padding: '2px 7px', fontSize: '0.7rem' }}>
                          {currentChildCategories.length}
                        </span>
                      </div>
                      <p style={{ fontSize: '0.72rem', color: '#059669', marginTop: 2, fontWeight: 600 }}>
                        {selectedSub ? `Under: ${selectedSub.name}` : 'No sub-category selected'}
                      </p>
                    </div>

                    <button
                      disabled={!selectedSub}
                      onClick={() => {
                        setTargetCat(selectedCat);
                        setTargetSub(selectedSub);
                        setShowAddChildModal(true);
                      }}
                      style={{
                        display: 'flex',
                        alignItems: 'center',
                        gap: 4,
                        background: selectedSub ? 'linear-gradient(135deg, #10B981 0%, #059669 100%)' : '#F1F5F9',
                        border: selectedSub ? 'none' : '1px solid var(--border)',
                        color: selectedSub ? '#fff' : 'var(--text-dim)',
                        padding: '6px 14px',
                        borderRadius: 6,
                        fontWeight: 600,
                        fontSize: '0.78rem',
                        boxShadow: selectedSub ? '0 2px 10px rgba(16, 185, 129, 0.25)' : 'none',
                        cursor: selectedSub ? 'pointer' : 'not-allowed'
                      }}
                    >
                      <Plus size={14} /> Add Service
                    </button>
                  </div>

                  {/* Column 3 List */}
                  <div style={{ padding: 12, display: 'flex', flexDirection: 'column', gap: 10, maxHeight: 580, overflowY: 'auto' }}>
                    {!selectedSub ? (
                      <div style={{ padding: 40, textAlign: 'center', color: 'var(--text-muted)' }}>
                        <p style={{ fontSize: '0.85rem' }}>Select a Sub-Category in the middle column first.</p>
                      </div>
                    ) : currentChildCategories.length === 0 ? (
                      <div style={{ padding: 40, textAlign: 'center', color: 'var(--text-muted)' }}>
                        <p style={{ fontSize: '0.85rem', marginBottom: 12 }}>No child services added under <strong>{selectedSub.name}</strong> yet.</p>
                        <button
                          onClick={() => {
                            setTargetCat(selectedCat);
                            setTargetSub(selectedSub);
                            setShowAddChildModal(true);
                          }}
                          style={{
                            background: '#ECFDF5',
                            border: '1px solid #A7F3D0',
                            color: '#059669',
                            padding: '6px 14px',
                            borderRadius: 6,
                            fontSize: '0.8rem',
                            fontWeight: 600,
                            cursor: 'pointer'
                          }}
                        >
                          + Add First Child Service
                        </button>
                      </div>
                    ) : (
                      currentChildCategories.map(ch => (
                        <div
                          key={ch.id}
                          style={{
                            padding: '14px 16px',
                            borderRadius: 10,
                            background: '#FFFFFF',
                            border: '1px solid var(--border)',
                            boxShadow: '0 2px 8px rgba(0,0,0,0.02)',
                            display: 'flex',
                            alignItems: 'center',
                            justifyContent: 'space-between',
                            gap: 12,
                            transition: 'all 0.15s ease'
                          }}
                        >
                          <div style={{ display: 'flex', alignItems: 'flex-start', gap: 10, flex: 1 }}>
                            <div style={{
                              width: 32,
                              height: 32,
                              borderRadius: 8,
                              background: '#ECFDF5',
                              border: '1px solid #A7F3D0',
                              display: 'flex',
                              alignItems: 'center',
                              justifyContent: 'center',
                              flexShrink: 0,
                              marginTop: 2
                            }}>
                              <Sparkles size={16} color="#059669" />
                            </div>
                            <div>
                              <p style={{ fontWeight: 700, fontSize: '0.9rem', color: 'var(--text-main)', lineHeight: 1.3 }}>
                                {ch.name}
                              </p>
                              <div style={{ display: 'flex', alignItems: 'center', gap: 8, marginTop: 4 }}>
                                <span style={{ fontSize: '0.72rem', color: 'var(--text-muted)', display: 'flex', alignItems: 'center', gap: 3 }}>
                                  <Clock size={12} color="var(--text-dim)" /> 30-45 mins
                                </span>
                                <span style={{ fontSize: '0.72rem', color: '#2563EB', fontWeight: 600 }}>
                                  • Instant Booking
                                </span>
                              </div>
                            </div>
                          </div>

                          <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
                            <button
                              onClick={() => handleDeleteChildCategory(selectedCat.id, selectedSub.id, ch.id, ch.name)}
                              title="Delete Service"
                              style={{
                                background: '#FEF2F2',
                                border: '1px solid #FECACA',
                                color: '#DC2626',
                                padding: '6px 8px',
                                borderRadius: 6,
                                cursor: 'pointer'
                              }}
                            >
                              <Trash2 size={13} />
                            </button>
                          </div>
                        </div>
                      ))
                    )}
                  </div>
                </div>

              </div>
            </div>
          )}

          {/* TAB 3: 3-COLUMN LOCATION MANAGEMENT (DISTRICT -> MANDAL -> VILLAGE) */}
          {activeTab === 'locations' && (
            <div style={{ display: 'flex', flexDirection: 'column', gap: 20 }}>
              
              {/* Interactive Breadcrumb Path Bar */}
              <div className="glass-panel" style={{
                padding: '14px 22px',
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'space-between',
                flexWrap: 'wrap',
                gap: 12
              }}>
                <div style={{ display: 'flex', alignItems: 'center', gap: 10, fontSize: '0.9rem', flexWrap: 'wrap' }}>
                  <span style={{ color: 'var(--text-muted)', display: 'flex', alignItems: 'center', gap: 6, fontWeight: 600 }}>
                    <MapPin size={17} color="#DE4915" /> All Districts ({locations.length})
                  </span>
                  <ChevronRight size={15} color="var(--text-dim)" />
                  <span style={{
                    fontWeight: 700,
                    background: selectedDistrict ? '#FFF4EF' : 'transparent',
                    color: selectedDistrict ? '#DE4915' : 'var(--text-dim)',
                    padding: '4px 12px',
                    borderRadius: 8,
                    border: selectedDistrict ? '1px solid rgba(222, 73, 21, 0.35)' : 'none',
                    display: 'flex',
                    alignItems: 'center',
                    gap: 6
                  }}>
                    <Building2 size={15} />
                    {selectedDistrict ? `${selectedDistrict.name} (${selectedDistrict.state || 'Andhra Pradesh'})` : 'Select District'}
                  </span>
                  <ChevronRight size={15} color="var(--text-dim)" />
                  <span style={{
                    fontWeight: 700,
                    background: selectedMandal ? '#FFFBEB' : 'transparent',
                    color: selectedMandal ? '#D97706' : 'var(--text-dim)',
                    padding: '4px 12px',
                    borderRadius: 8,
                    border: selectedMandal ? '1px solid #FDE68A' : 'none',
                    display: 'flex',
                    alignItems: 'center',
                    gap: 6
                  }}>
                    <Navigation size={14} />
                    {selectedMandal?.name || 'Select Mandal'}
                  </span>
                </div>

                <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
                  <span style={{ fontSize: '0.78rem', color: 'var(--text-muted)', background: '#F1F5F9', border: '1px solid var(--border)', padding: '4px 10px', borderRadius: 20 }}>
                    Active Coverage: <strong>{currentVillages.length} Villages / Wards</strong>
                  </span>
                </div>
              </div>

              {/* 3-Column Drill-Down Grid for Locations */}
              <div style={{
                display: 'grid',
                gridTemplateColumns: 'minmax(280px, 1fr) minmax(300px, 1.05fr) minmax(360px, 1.25fr)',
                gap: 20,
                alignItems: 'start'
              }}>
                
                {/* ================= COLUMN 1: DISTRICTS ================= */}
                <div className="glass-panel" style={{ display: 'flex', flexDirection: 'column', minHeight: 640 }}>
                  {/* Column 1 Header */}
                  <div style={{ padding: '16px 18px', borderBottom: '1px solid var(--border)', display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
                    <div>
                      <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
                        <span style={{ width: 8, height: 8, borderRadius: '50%', background: '#DE4915' }} />
                        <h3 style={{ fontSize: '1rem', fontWeight: 700, color: 'var(--text-main)' }}>1. Districts</h3>
                        <span className="badge" style={{ background: '#FFF4EF', color: '#DE4915', border: '1px solid rgba(222, 73, 21, 0.25)', padding: '2px 7px', fontSize: '0.7rem' }}>
                          {locations.length}
                        </span>
                      </div>
                      <p style={{ fontSize: '0.72rem', color: 'var(--text-muted)', marginTop: 2 }}>Click district to explore mandals</p>
                    </div>

                    <button
                      onClick={() => setShowAddDistrictModal(true)}
                      style={{
                        display: 'flex',
                        alignItems: 'center',
                        gap: 4,
                        background: 'linear-gradient(135deg, #DE4915 0%, #B8350B 100%)',
                        color: '#fff',
                        padding: '6px 12px',
                        borderRadius: 6,
                        fontWeight: 600,
                        fontSize: '0.78rem',
                        boxShadow: '0 2px 8px rgba(222, 73, 21, 0.25)',
                        cursor: 'pointer'
                      }}
                    >
                      <Plus size={14} /> New
                    </button>
                  </div>

                  {/* Column 1 List */}
                  <div style={{ padding: 12, display: 'flex', flexDirection: 'column', gap: 8, maxHeight: 580, overflowY: 'auto' }}>
                    {locations.length === 0 ? (
                      <div style={{ padding: 40, textAlign: 'center', color: 'var(--text-muted)' }}>
                        <p style={{ fontSize: '0.85rem' }}>No districts added yet.</p>
                      </div>
                    ) : (
                      locations.map(dist => {
                        const isSelected = selectedDistrict?.id === dist.id;
                        return (
                          <div
                            key={dist.id}
                            onClick={() => handleSelectDistrict(dist)}
                            style={{
                              padding: '12px 14px',
                              borderRadius: 10,
                              cursor: 'pointer',
                              display: 'flex',
                              alignItems: 'center',
                              justifyContent: 'space-between',
                              transition: 'all 0.18s ease',
                              background: isSelected ? '#FFF4EF' : '#F8FAFC',
                              border: isSelected ? '1.5px solid #DE4915' : '1px solid var(--border)',
                              boxShadow: isSelected ? '0 2px 10px rgba(222, 73, 21, 0.15)' : 'none'
                            }}
                          >
                            <div style={{ display: 'flex', alignItems: 'center', gap: 10, flex: 1, minWidth: 0 }}>
                              <div style={{
                                width: 34,
                                height: 34,
                                borderRadius: 8,
                                background: isSelected ? '#DE4915' : '#FFFFFF',
                                border: isSelected ? 'none' : '1px solid var(--border)',
                                display: 'flex',
                                alignItems: 'center',
                                justifyContent: 'center',
                                flexShrink: 0
                              }}>
                                <Building2 size={17} color={isSelected ? '#fff' : '#DE4915'} />
                              </div>
                              <div style={{ overflow: 'hidden' }}>
                                <p style={{ fontWeight: 700, fontSize: '0.88rem', color: isSelected ? '#DE4915' : 'var(--text-main)', whiteSpace: 'nowrap', textOverflow: 'ellipsis', overflow: 'hidden' }}>
                                  {dist.name}
                                </p>
                                <p style={{ fontSize: '0.72rem', color: isSelected ? '#DE4915' : 'var(--text-muted)' }}>
                                  {dist.state || 'Andhra Pradesh'} • {dist.mandals?.length || 0} Mandals
                                </p>
                              </div>
                            </div>

                            <div style={{ display: 'flex', alignItems: 'center', gap: 6 }}>
                              <button
                                onClick={(e) => {
                                  e.stopPropagation();
                                  handleDeleteDistrict(dist.id, dist.name);
                                }}
                                title="Delete District"
                                style={{
                                  background: 'none',
                                  border: 'none',
                                  color: 'var(--text-dim)',
                                  padding: 4,
                                  cursor: 'pointer',
                                  borderRadius: 4
                                }}
                                onMouseEnter={(e) => e.currentTarget.style.color = '#EF4444'}
                                onMouseLeave={(e) => e.currentTarget.style.color = 'var(--text-dim)'}
                              >
                                <Trash2 size={13} />
                              </button>
                              <ChevronRight size={16} color={isSelected ? '#DE4915' : 'var(--text-dim)'} />
                            </div>
                          </div>
                        );
                      })
                    )}
                  </div>
                </div>

                {/* ================= COLUMN 2: MANDALS ================= */}
                <div className="glass-panel" style={{ display: 'flex', flexDirection: 'column', minHeight: 640 }}>
                  {/* Column 2 Header */}
                  <div style={{ padding: '16px 18px', borderBottom: '1px solid var(--border)', display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
                    <div>
                      <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
                        <span style={{ width: 8, height: 8, borderRadius: '50%', background: '#F59E0B' }} />
                        <h3 style={{ fontSize: '1rem', fontWeight: 700, color: 'var(--text-main)' }}>2. Mandals</h3>
                        <span className="badge" style={{ background: '#FFFBEB', color: '#D97706', border: '1px solid #FDE68A', padding: '2px 7px', fontSize: '0.7rem' }}>
                          {currentMandals.length}
                        </span>
                      </div>
                      <p style={{ fontSize: '0.72rem', color: '#DE4915', marginTop: 2, fontWeight: 600 }}>
                        {selectedDistrict ? `In District: ${selectedDistrict.name}` : 'No district selected'}
                      </p>
                    </div>

                    <button
                      disabled={!selectedDistrict}
                      onClick={() => {
                        setTargetDistrict(selectedDistrict);
                        setShowAddMandalModal(true);
                      }}
                      style={{
                        display: 'flex',
                        alignItems: 'center',
                        gap: 4,
                        background: selectedDistrict ? '#FFFBEB' : '#F1F5F9',
                        border: selectedDistrict ? '1px solid #FDE68A' : '1px solid var(--border)',
                        color: selectedDistrict ? '#D97706' : 'var(--text-dim)',
                        padding: '6px 12px',
                        borderRadius: 6,
                        fontWeight: 600,
                        fontSize: '0.78rem',
                        cursor: selectedDistrict ? 'pointer' : 'not-allowed'
                      }}
                    >
                      <Plus size={14} /> Add Mandal
                    </button>
                  </div>

                  {/* Column 2 List */}
                  <div style={{ padding: 12, display: 'flex', flexDirection: 'column', gap: 8, maxHeight: 580, overflowY: 'auto' }}>
                    {!selectedDistrict ? (
                      <div style={{ padding: 40, textAlign: 'center', color: 'var(--text-muted)' }}>
                        <p style={{ fontSize: '0.85rem' }}>Select a district on the left first.</p>
                      </div>
                    ) : currentMandals.length === 0 ? (
                      <div style={{ padding: 40, textAlign: 'center', color: 'var(--text-muted)' }}>
                        <p style={{ fontSize: '0.85rem', marginBottom: 12 }}>No mandals added under <strong>{selectedDistrict.name}</strong> yet.</p>
                        <button
                          onClick={() => {
                            setTargetDistrict(selectedDistrict);
                            setShowAddMandalModal(true);
                          }}
                          style={{
                            background: '#FFFBEB',
                            border: '1px solid #FDE68A',
                            color: '#D97706',
                            padding: '6px 14px',
                            borderRadius: 6,
                            fontSize: '0.8rem',
                            fontWeight: 600,
                            cursor: 'pointer'
                          }}
                        >
                          + Add First Mandal
                        </button>
                      </div>
                    ) : (
                      currentMandals.map(mnd => {
                        const isSelected = selectedMandal?.id === mnd.id;
                        return (
                          <div
                            key={mnd.id}
                            onClick={() => handleSelectMandal(mnd)}
                            style={{
                              padding: '12px 14px',
                              borderRadius: 10,
                              cursor: 'pointer',
                              display: 'flex',
                              alignItems: 'center',
                              justifyContent: 'space-between',
                              transition: 'all 0.18s ease',
                              background: isSelected ? '#FFFBEB' : '#F8FAFC',
                              border: isSelected ? '1.5px solid #F59E0B' : '1px solid var(--border)',
                              boxShadow: isSelected ? '0 2px 10px rgba(245, 158, 11, 0.15)' : 'none'
                            }}
                          >
                            <div style={{ display: 'flex', alignItems: 'center', gap: 10, flex: 1, minWidth: 0 }}>
                              <div style={{
                                width: 32,
                                height: 32,
                                borderRadius: 8,
                                background: isSelected ? '#FEF3C7' : '#FFFFFF',
                                border: isSelected ? 'none' : '1px solid var(--border)',
                                display: 'flex',
                                alignItems: 'center',
                                justifyContent: 'center',
                                flexShrink: 0
                              }}>
                                <Navigation size={16} color={isSelected ? '#D97706' : 'var(--text-muted)'} />
                              </div>
                              <div style={{ overflow: 'hidden' }}>
                                <p style={{ fontWeight: 600, fontSize: '0.88rem', color: isSelected ? '#92400E' : 'var(--text-main)', whiteSpace: 'nowrap', textOverflow: 'ellipsis', overflow: 'hidden' }}>
                                  {mnd.name}
                                </p>
                                <p style={{ fontSize: '0.72rem', color: isSelected ? '#D97706' : 'var(--text-muted)' }}>
                                  {mnd.villages?.length || 0} Villages / Wards
                                </p>
                              </div>
                            </div>

                            <div style={{ display: 'flex', alignItems: 'center', gap: 6 }}>
                              <button
                                onClick={(e) => {
                                  e.stopPropagation();
                                  handleDeleteMandal(selectedDistrict.id, mnd.id, mnd.name);
                                }}
                                title="Delete Mandal"
                                style={{
                                  background: 'none',
                                  border: 'none',
                                  color: 'var(--text-dim)',
                                  padding: 4,
                                  cursor: 'pointer',
                                  borderRadius: 4
                                }}
                                onMouseEnter={(e) => e.currentTarget.style.color = '#EF4444'}
                                onMouseLeave={(e) => e.currentTarget.style.color = 'var(--text-dim)'}
                              >
                                <Trash2 size={13} />
                              </button>
                              <ChevronRight size={16} color={isSelected ? '#F59E0B' : 'var(--text-dim)'} />
                            </div>
                          </div>
                        );
                      })
                    )}
                  </div>
                </div>

                {/* ================= COLUMN 3: VILLAGES / WARDS ================= */}
                <div className="glass-panel" style={{ display: 'flex', flexDirection: 'column', minHeight: 640 }}>
                  {/* Column 3 Header */}
                  <div style={{ padding: '16px 18px', borderBottom: '1px solid var(--border)', display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
                    <div>
                      <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
                        <span style={{ width: 8, height: 8, borderRadius: '50%', background: '#10B981' }} />
                        <h3 style={{ fontSize: '1rem', fontWeight: 700, color: 'var(--text-main)' }}>3. Villages / Wards</h3>
                        <span className="badge" style={{ background: '#ECFDF5', color: '#059669', border: '1px solid #A7F3D0', padding: '2px 7px', fontSize: '0.7rem' }}>
                          {currentVillages.length}
                        </span>
                      </div>
                      <p style={{ fontSize: '0.72rem', color: '#059669', marginTop: 2, fontWeight: 600 }}>
                        {selectedMandal ? `Under Mandal: ${selectedMandal.name}` : 'No mandal selected'}
                      </p>
                    </div>

                    <button
                      disabled={!selectedMandal}
                      onClick={() => {
                        setTargetDistrict(selectedDistrict);
                        setTargetMandal(selectedMandal);
                        setShowAddVillageModal(true);
                      }}
                      style={{
                        display: 'flex',
                        alignItems: 'center',
                        gap: 4,
                        background: selectedMandal ? 'linear-gradient(135deg, #10B981 0%, #059669 100%)' : '#F1F5F9',
                        border: selectedMandal ? 'none' : '1px solid var(--border)',
                        color: selectedMandal ? '#fff' : 'var(--text-dim)',
                        padding: '6px 14px',
                        borderRadius: 6,
                        fontWeight: 600,
                        fontSize: '0.78rem',
                        boxShadow: selectedMandal ? '0 2px 10px rgba(16, 185, 129, 0.25)' : 'none',
                        cursor: selectedMandal ? 'pointer' : 'not-allowed'
                      }}
                    >
                      <Plus size={14} /> Add Village
                    </button>
                  </div>

                  {/* Column 3 List */}
                  <div style={{ padding: 12, display: 'flex', flexDirection: 'column', gap: 10, maxHeight: 580, overflowY: 'auto' }}>
                    {!selectedMandal ? (
                      <div style={{ padding: 40, textAlign: 'center', color: 'var(--text-muted)' }}>
                        <p style={{ fontSize: '0.85rem' }}>Select a Mandal in the middle column first.</p>
                      </div>
                    ) : currentVillages.length === 0 ? (
                      <div style={{ padding: 40, textAlign: 'center', color: 'var(--text-muted)' }}>
                        <p style={{ fontSize: '0.85rem', marginBottom: 12 }}>No villages/wards added under <strong>{selectedMandal.name}</strong> yet.</p>
                        <button
                          onClick={() => {
                            setTargetDistrict(selectedDistrict);
                            setTargetMandal(selectedMandal);
                            setShowAddVillageModal(true);
                          }}
                          style={{
                            background: '#ECFDF5',
                            border: '1px solid #A7F3D0',
                            color: '#059669',
                            padding: '6px 14px',
                            borderRadius: 6,
                            fontSize: '0.8rem',
                            fontWeight: 600,
                            cursor: 'pointer'
                          }}
                        >
                          + Add First Village / Ward
                        </button>
                      </div>
                    ) : (
                      currentVillages.map(vlg => (
                        <div
                          key={vlg.id}
                          style={{
                            padding: '14px 16px',
                            borderRadius: 10,
                            background: '#FFFFFF',
                            border: '1px solid var(--border)',
                            boxShadow: '0 2px 8px rgba(0,0,0,0.02)',
                            display: 'flex',
                            alignItems: 'center',
                            justifyContent: 'space-between',
                            gap: 12,
                            transition: 'all 0.15s ease'
                          }}
                        >
                          <div style={{ display: 'flex', alignItems: 'flex-start', gap: 10, flex: 1 }}>
                            <div style={{
                              width: 32,
                              height: 32,
                              borderRadius: 8,
                              background: '#ECFDF5',
                              border: '1px solid #A7F3D0',
                              display: 'flex',
                              alignItems: 'center',
                              justifyContent: 'center',
                              flexShrink: 0,
                              marginTop: 2
                            }}>
                              <MapPin size={16} color="#059669" />
                            </div>
                            <div>
                              <p style={{ fontWeight: 700, fontSize: '0.9rem', color: 'var(--text-main)', lineHeight: 1.3 }}>
                                {vlg.name}
                              </p>
                              <div style={{ display: 'flex', alignItems: 'center', gap: 8, marginTop: 4 }}>
                                {vlg.pincode && (
                                  <span style={{ fontSize: '0.72rem', color: 'var(--text-muted)', display: 'flex', alignItems: 'center', gap: 3 }}>
                                    PIN: {vlg.pincode}
                                  </span>
                                )}
                                <span style={{ fontSize: '0.72rem', color: '#059669', fontWeight: 600 }}>
                                  • Hyperlocal Active
                                </span>
                              </div>
                            </div>
                          </div>

                          <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
                            <button
                              onClick={() => handleDeleteVillage(selectedDistrict.id, selectedMandal.id, vlg.id, vlg.name)}
                              title="Delete Village"
                              style={{
                                background: '#FEF2F2',
                                border: '1px solid #FECACA',
                                color: '#DC2626',
                                padding: '6px 8px',
                                borderRadius: 6,
                                cursor: 'pointer'
                              }}
                            >
                              <Trash2 size={13} />
                            </button>
                          </div>
                        </div>
                      ))
                    )}
                  </div>
                </div>

              </div>
            </div>
          )}

          {/* TAB 4: APP CUSTOMERS */}
          {activeTab === 'customers' && (
            <div style={{ display: 'flex', flexDirection: 'column', gap: 24 }}>
              {/* Metric KPI Cards */}
              <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(230px, 1fr))', gap: 20 }}>
                <div className="glass-panel" style={{ padding: '22px' }}>
                  <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start' }}>
                    <p style={{ fontSize: '0.82rem', color: 'var(--text-muted)', fontWeight: 600 }}>REGISTERED CUSTOMERS</p>
                    <div style={{ width: 36, height: 36, borderRadius: 10, background: '#FFF4EF', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
                      <Users size={19} color="#DE4915" />
                    </div>
                  </div>
                  <h3 style={{ fontSize: '1.8rem', fontWeight: 800, marginTop: 10, color: 'var(--text-main)' }}>
                    {customers.length}
                  </h3>
                  <p style={{ fontSize: '0.75rem', color: '#059669', fontWeight: 600, marginTop: 8 }}>
                    • Active App Users in Andhra Pradesh
                  </p>
                </div>

                <div className="glass-panel" style={{ padding: '22px' }}>
                  <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start' }}>
                    <p style={{ fontSize: '0.82rem', color: 'var(--text-muted)', fontWeight: 600 }}>ACTIVE BOOKINGS</p>
                    <div style={{ width: 36, height: 36, borderRadius: 10, background: '#ECFDF5', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
                      <Clock size={19} color="#059669" />
                    </div>
                  </div>
                  <h3 style={{ fontSize: '1.8rem', fontWeight: 800, marginTop: 10, color: '#059669' }}>
                    {orders.filter(o => o.status !== 'completed' && o.status !== 'cancelled').length}
                  </h3>
                  <p style={{ fontSize: '0.75rem', color: 'var(--text-muted)', marginTop: 8 }}>
                    In dispatch or in-progress
                  </p>
                </div>

                <div className="glass-panel" style={{ padding: '22px' }}>
                  <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start' }}>
                    <p style={{ fontSize: '0.82rem', color: 'var(--text-muted)', fontWeight: 600 }}>TOTAL WALLET BALANCE</p>
                    <div style={{ width: 36, height: 36, borderRadius: 10, background: '#EFF6FF', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
                      <DollarSign size={19} color="#2563EB" />
                    </div>
                  </div>
                  <h3 style={{ fontSize: '1.8rem', fontWeight: 800, marginTop: 10, color: '#2563EB' }}>
                    ₹{customers.reduce((acc, c) => acc + (c.walletBalance || 0), 0).toLocaleString()}
                  </h3>
                  <p style={{ fontSize: '0.75rem', color: 'var(--text-muted)', marginTop: 8 }}>
                    Loki Customer Cash credits
                  </p>
                </div>

                <div className="glass-panel" style={{ padding: '22px' }}>
                  <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start' }}>
                    <p style={{ fontSize: '0.82rem', color: 'var(--text-muted)', fontWeight: 600 }}>HYPERLOCAL REACH</p>
                    <div style={{ width: 36, height: 36, borderRadius: 10, background: '#F5F3FF', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
                      <MapPin size={19} color="#7C3AED" />
                    </div>
                  </div>
                  <h3 style={{ fontSize: '1.8rem', fontWeight: 800, marginTop: 10, color: '#7C3AED' }}>
                    {locations.reduce((acc, d) => acc + (d.mandals?.reduce((mAcc, m) => mAcc + (m.villages?.length || 0), 0) || 0), 0)} Wards
                  </h3>
                  <p style={{ fontSize: '0.75rem', color: 'var(--text-muted)', marginTop: 8 }}>
                    Hyderabad & Rangareddy
                  </p>
                </div>
              </div>

              {/* Search & Actions Bar */}
              <div className="glass-panel" style={{ padding: '16px 20px', display: 'flex', alignItems: 'center', justifyContent: 'space-between', gap: 16 }}>
                <div style={{ display: 'flex', alignItems: 'center', gap: 10, flex: 1, maxWidth: 460 }}>
                  <div style={{ position: 'relative', width: '100%' }}>
                    <Search size={16} color="var(--text-muted)" style={{ position: 'absolute', left: 12, top: 12 }} />
                    <input
                      type="text"
                      placeholder="Search customers by name, phone, address, village..."
                      value={customerSearch}
                      onChange={(e) => setCustomerSearch(e.target.value)}
                      style={{
                        width: '100%',
                        padding: '10px 14px 10px 38px',
                        borderRadius: 8,
                        background: '#F8FAFC',
                        border: '1px solid var(--border)',
                        color: 'var(--text-main)',
                        fontSize: '0.86rem',
                        outline: 'none'
                      }}
                    />
                  </div>
                  {customerSearch && (
                    <button
                      onClick={() => setCustomerSearch('')}
                      style={{ background: '#F1F5F9', border: 'none', padding: '8px 12px', borderRadius: 6, fontSize: '0.75rem', color: 'var(--text-muted)', cursor: 'pointer' }}
                    >
                      Clear
                    </button>
                  )}
                </div>

                <div style={{ display: 'flex', alignItems: 'center', gap: 12 }}>
                  <span style={{ fontSize: '0.82rem', color: 'var(--text-muted)', fontWeight: 600 }}>
                    Showing {filteredCustomers.length} of {customers.length} customers
                  </span>
                  <button
                    onClick={() => setShowAddCustomerModal(true)}
                    style={{
                      display: 'flex',
                      alignItems: 'center',
                      gap: 6,
                      background: 'linear-gradient(135deg, #DE4915 0%, #B8350B 100%)',
                      color: '#fff',
                      padding: '8px 16px',
                      borderRadius: 8,
                      fontWeight: 600,
                      fontSize: '0.82rem',
                      boxShadow: '0 4px 12px rgba(222, 73, 21, 0.25)',
                      cursor: 'pointer'
                    }}
                  >
                    <Plus size={15} /> Add Customer
                  </button>
                </div>
              </div>

              {/* Customers Data Table View */}
              {filteredCustomers.length === 0 ? (
                <div className="glass-panel" style={{ padding: 60, textAlign: 'center', color: 'var(--text-muted)' }}>
                  <Users size={42} color="#CBD5E1" style={{ margin: '0 auto 12px' }} />
                  <h4 style={{ fontSize: '1.1rem', fontWeight: 700, color: 'var(--text-main)' }}>No customers found</h4>
                  <p style={{ fontSize: '0.85rem', marginTop: 4 }}>Try clearing your search query or onboard a new customer.</p>
                </div>
              ) : (
                <div className="glass-panel" style={{ padding: 0, overflow: 'hidden' }}>
                  <div style={{ overflowX: 'auto' }}>
                    <table style={{ width: '100%', minWidth: 980, borderCollapse: 'collapse', textAlign: 'left', fontSize: '0.85rem' }}>
                      <thead>
                        <tr style={{ background: '#F8FAFC', borderBottom: '1px solid var(--border)' }}>
                          <th style={{ padding: '14px 20px', fontWeight: 700, color: 'var(--text-muted)', fontSize: '0.75rem', letterSpacing: '0.04em' }}>CUSTOMER</th>
                          <th style={{ padding: '14px 16px', fontWeight: 700, color: 'var(--text-muted)', fontSize: '0.75rem', letterSpacing: '0.04em' }}>CONTACT INFO</th>
                          <th style={{ padding: '14px 16px', fontWeight: 700, color: 'var(--text-muted)', fontSize: '0.75rem', letterSpacing: '0.04em' }}>COVERAGE LOCATION</th>
                          <th style={{ padding: '14px 16px', fontWeight: 700, color: 'var(--text-muted)', fontSize: '0.75rem', letterSpacing: '0.04em' }}>WALLET</th>
                          <th style={{ padding: '14px 16px', fontWeight: 700, color: 'var(--text-muted)', fontSize: '0.75rem', letterSpacing: '0.04em' }}>BOOKINGS</th>
                          <th style={{ padding: '14px 16px', fontWeight: 700, color: 'var(--text-muted)', fontSize: '0.75rem', letterSpacing: '0.04em' }}>APP STATUS</th>
                          <th style={{ padding: '14px 20px', fontWeight: 700, color: 'var(--text-muted)', fontSize: '0.75rem', letterSpacing: '0.04em', textAlign: 'right' }}>ACTIONS</th>
                        </tr>
                      </thead>
                      <tbody>
                        {filteredCustomers.map((cust, idx) => (
                          <tr
                            key={cust.id}
                            style={{
                              borderBottom: '1px solid var(--border)',
                              background: idx % 2 === 0 ? '#FFFFFF' : '#FAFBFD',
                              transition: 'background 0.15s ease'
                            }}
                          >
                            {/* 1. Customer Name & ID */}
                            <td style={{ padding: '14px 20px' }}>
                              <div style={{ display: 'flex', alignItems: 'center', gap: 12 }}>
                                <div style={{
                                  width: 36,
                                  height: 36,
                                  borderRadius: '50%',
                                  background: '#FFF4EF',
                                  border: '1.5px solid #FFD3C2',
                                  display: 'flex',
                                  alignItems: 'center',
                                  justifyContent: 'center',
                                  fontWeight: 700,
                                  fontSize: '0.9rem',
                                  color: '#DE4915',
                                  flexShrink: 0
                                }}>
                                  {cust.name ? cust.name.charAt(0).toUpperCase() : 'U'}
                                </div>
                                <div>
                                  <p style={{ fontWeight: 700, color: 'var(--text-main)', fontSize: '0.9rem' }}>
                                    {cust.name}
                                  </p>
                                  <p style={{ fontSize: '0.72rem', color: 'var(--text-muted)', marginTop: 1 }}>
                                    ID: {cust.id}
                                  </p>
                                </div>
                              </div>
                            </td>

                            {/* 2. Contact */}
                            <td style={{ padding: '14px 16px' }}>
                              <div style={{ display: 'flex', flexDirection: 'column', gap: 2 }}>
                                <span style={{ fontWeight: 600, color: 'var(--text-main)', display: 'flex', alignItems: 'center', gap: 6 }}>
                                  <Phone size={12} color="#DE4915" /> {cust.phone}
                                </span>
                                {cust.email && (
                                  <span style={{ fontSize: '0.75rem', color: 'var(--text-muted)', display: 'flex', alignItems: 'center', gap: 6 }}>
                                    <Mail size={12} color="#64748B" /> {cust.email}
                                  </span>
                                )}
                              </div>
                            </td>

                            {/* 3. Coverage Location */}
                            <td style={{ padding: '14px 16px' }}>
                              <div style={{ display: 'flex', flexDirection: 'column', gap: 2 }}>
                                <span style={{ fontWeight: 600, color: 'var(--text-main)' }}>
                                  {cust.village || 'Madhapur'}, {cust.mandal || 'Serilingampally'}
                                </span>
                                <span style={{ fontSize: '0.74rem', color: 'var(--text-muted)', display: 'flex', alignItems: 'center', gap: 4 }}>
                                  <MapPin size={11} color="#059669" /> {cust.address ? `${cust.address}, ` : ''}{cust.district || 'Hyderabad'}
                                </span>
                              </div>
                            </td>

                            {/* 4. Wallet Balance */}
                            <td style={{ padding: '14px 16px' }}>
                              <span style={{ fontWeight: 700, color: '#2563EB', fontSize: '0.92rem' }}>
                                ₹{cust.walletBalance || 0}
                              </span>
                            </td>

                            {/* 5. Bookings Count */}
                            <td style={{ padding: '14px 16px' }}>
                              <span style={{
                                background: '#F1F5F9',
                                color: 'var(--text-main)',
                                padding: '3px 8px',
                                borderRadius: 6,
                                fontWeight: 600,
                                fontSize: '0.76rem'
                              }}>
                                {cust.totalOrders || 0} orders
                              </span>
                            </td>

                            {/* 6. Status */}
                            <td style={{ padding: '14px 16px' }}>
                              <span style={{
                                display: 'inline-flex',
                                alignItems: 'center',
                                gap: 4,
                                background: '#ECFDF5',
                                color: '#059669',
                                border: '1px solid #A7F3D0',
                                padding: '3px 8px',
                                borderRadius: 6,
                                fontSize: '0.74rem',
                                fontWeight: 600
                              }}>
                                <span style={{ width: 6, height: 6, borderRadius: '50%', background: '#10B981' }} />
                                Active User
                              </span>
                            </td>

                            {/* 7. Actions */}
                            <td style={{ padding: '14px 20px', textAlign: 'right' }}>
                              <button
                                onClick={() => handleDeleteCustomer(cust.id, cust.name)}
                                title="Remove Customer"
                                style={{
                                  background: '#FEF2F2',
                                  border: '1px solid #FECACA',
                                  color: '#DC2626',
                                  padding: '6px 9px',
                                  borderRadius: 6,
                                  cursor: 'pointer',
                                  display: 'inline-flex',
                                  alignItems: 'center',
                                  gap: 4,
                                  fontSize: '0.75rem',
                                  fontWeight: 600
                                }}
                              >
                                <Trash2 size={13} /> Delete
                              </button>
                            </td>
                          </tr>
                        ))}
                      </tbody>
                    </table>
                  </div>

                  {/* Table Footer */}
                  <div style={{
                    padding: '12px 20px',
                    background: '#F8FAFC',
                    borderTop: '1px solid var(--border)',
                    display: 'flex',
                    alignItems: 'center',
                    justifyContent: 'space-between',
                    fontSize: '0.78rem',
                    color: 'var(--text-muted)'
                  }}>
                    <span>Total <strong>{filteredCustomers.length}</strong> customers listed</span>
                    <span>High-density rows optimized for scale</span>
                  </div>
                </div>
              )}
            </div>
          )}

          {/* TAB 5: SERVICE PARTNERS FLEET */}
          {activeTab === 'partners' && (
            <div style={{ display: 'flex', flexDirection: 'column', gap: 24 }}>
              {/* Metric KPI Cards */}
              <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(230px, 1fr))', gap: 20 }}>
                <div className="glass-panel" style={{ padding: '22px' }}>
                  <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start' }}>
                    <p style={{ fontSize: '0.82rem', color: 'var(--text-muted)', fontWeight: 600 }}>ONBOARDED PARTNERS</p>
                    <div style={{ width: 36, height: 36, borderRadius: 10, background: '#FFF4EF', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
                      <Briefcase size={19} color="#DE4915" />
                    </div>
                  </div>
                  <h3 style={{ fontSize: '1.8rem', fontWeight: 800, marginTop: 10, color: 'var(--text-main)' }}>
                    {partners.length}
                  </h3>
                  <p style={{ fontSize: '0.75rem', color: '#DE4915', fontWeight: 600, marginTop: 8 }}>
                    Partner App Registrations
                  </p>
                </div>

                <div className="glass-panel" style={{ padding: '22px' }}>
                  <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start' }}>
                    <p style={{ fontSize: '0.82rem', color: 'var(--text-muted)', fontWeight: 600 }}>ONLINE FLEET (DUTY ON)</p>
                    <div style={{ width: 36, height: 36, borderRadius: 10, background: '#ECFDF5', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
                      <Power size={19} color="#059669" />
                    </div>
                  </div>
                  <h3 style={{ fontSize: '1.8rem', fontWeight: 800, marginTop: 10, color: '#059669' }}>
                    {partnerOnlineCount}
                  </h3>
                  <p style={{ fontSize: '0.75rem', color: '#059669', fontWeight: 600, marginTop: 8 }}>
                    • Ready to receive customer orders
                  </p>
                </div>

                <div className="glass-panel" style={{ padding: '22px' }}>
                  <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start' }}>
                    <p style={{ fontSize: '0.82rem', color: 'var(--text-muted)', fontWeight: 600 }}>KYC VERIFICATION QUEUE</p>
                    <div style={{ width: 36, height: 36, borderRadius: 10, background: '#FFFBEB', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
                      <ShieldAlert size={19} color="#D97706" />
                    </div>
                  </div>
                  <h3 style={{ fontSize: '1.8rem', fontWeight: 800, marginTop: 10, color: partnerPendingCount > 0 ? '#D97706' : '#059669' }}>
                    {partnerPendingCount}
                  </h3>
                  <p style={{ fontSize: '0.75rem', color: partnerPendingCount > 0 ? '#D97706' : 'var(--text-muted)', marginTop: 8, fontWeight: 600 }}>
                    {partnerPendingCount > 0 ? 'Aadhaar / ID Verification Pending' : 'All Partners Verified'}
                  </p>
                </div>

                <div className="glass-panel" style={{ padding: '22px' }}>
                  <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start' }}>
                    <p style={{ fontSize: '0.82rem', color: 'var(--text-muted)', fontWeight: 600 }}>AVERAGE FLEET RATING</p>
                    <div style={{ width: 36, height: 36, borderRadius: 10, background: '#FEF9C3', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
                      <Star size={19} color="#CA8A04" />
                    </div>
                  </div>
                  <h3 style={{ fontSize: '1.8rem', fontWeight: 800, marginTop: 10, color: '#CA8A04' }}>
                    4.9 ★
                  </h3>
                  <p style={{ fontSize: '0.75rem', color: 'var(--text-muted)', marginTop: 8 }}>
                    Based on customer reviews
                  </p>
                </div>
              </div>

              {/* Filter Tabs & Search Bar */}
              <div className="glass-panel" style={{ padding: '16px 20px', display: 'flex', alignItems: 'center', justifyContent: 'space-between', gap: 16, flexWrap: 'wrap' }}>
                <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
                  <button
                    onClick={() => setPartnerFilter('all')}
                    style={{
                      padding: '8px 14px',
                      borderRadius: 8,
                      fontSize: '0.82rem',
                      fontWeight: 600,
                      cursor: 'pointer',
                      background: partnerFilter === 'all' ? '#192338' : '#F1F5F9',
                      color: partnerFilter === 'all' ? '#fff' : 'var(--text-muted)',
                      border: 'none'
                    }}
                  >
                    All Partners ({partners.length})
                  </button>
                  <button
                    onClick={() => setPartnerFilter('online')}
                    style={{
                      padding: '8px 14px',
                      borderRadius: 8,
                      fontSize: '0.82rem',
                      fontWeight: 600,
                      cursor: 'pointer',
                      background: partnerFilter === 'online' ? '#10B981' : '#F1F5F9',
                      color: partnerFilter === 'online' ? '#fff' : 'var(--text-muted)',
                      border: 'none'
                    }}
                  >
                    Online Now ({partnerOnlineCount})
                  </button>
                  <button
                    onClick={() => setPartnerFilter('pending')}
                    style={{
                      padding: '8px 14px',
                      borderRadius: 8,
                      fontSize: '0.82rem',
                      fontWeight: 600,
                      cursor: 'pointer',
                      background: partnerFilter === 'pending' ? '#F59E0B' : '#F1F5F9',
                      color: partnerFilter === 'pending' ? '#fff' : 'var(--text-muted)',
                      border: 'none'
                    }}
                  >
                    KYC Pending ({partnerPendingCount})
                  </button>
                  <button
                    onClick={() => setPartnerFilter('approved')}
                    style={{
                      padding: '8px 14px',
                      borderRadius: 8,
                      fontSize: '0.82rem',
                      fontWeight: 600,
                      cursor: 'pointer',
                      background: partnerFilter === 'approved' ? '#059669' : '#F1F5F9',
                      color: partnerFilter === 'approved' ? '#fff' : 'var(--text-muted)',
                      border: 'none'
                    }}
                  >
                    Verified ({partnerVerifiedCount})
                  </button>
                </div>

                <div style={{ display: 'flex', alignItems: 'center', gap: 12, flex: 1, maxWidth: 420, minWidth: 260 }}>
                  <div style={{ position: 'relative', width: '100%' }}>
                    <Search size={16} color="var(--text-muted)" style={{ position: 'absolute', left: 12, top: 12 }} />
                    <input
                      type="text"
                      placeholder="Search by partner name, trade, phone..."
                      value={partnerSearch}
                      onChange={(e) => setPartnerSearch(e.target.value)}
                      style={{
                        width: '100%',
                        padding: '10px 14px 10px 38px',
                        borderRadius: 8,
                        background: '#F8FAFC',
                        border: '1px solid var(--border)',
                        color: 'var(--text-main)',
                        fontSize: '0.86rem',
                        outline: 'none'
                      }}
                    />
                  </div>
                  {partnerSearch && (
                    <button
                      onClick={() => setPartnerSearch('')}
                      style={{ background: '#F1F5F9', border: 'none', padding: '8px 12px', borderRadius: 6, fontSize: '0.75rem', color: 'var(--text-muted)', cursor: 'pointer' }}
                    >
                      Clear
                    </button>
                  )}
                  <button
                    onClick={() => setShowAddPartnerModal(true)}
                    style={{
                      display: 'flex',
                      alignItems: 'center',
                      gap: 6,
                      background: 'linear-gradient(135deg, #DE4915 0%, #B8350B 100%)',
                      color: '#fff',
                      padding: '8px 16px',
                      borderRadius: 8,
                      fontWeight: 600,
                      fontSize: '0.82rem',
                      boxShadow: '0 4px 12px rgba(222, 73, 21, 0.25)',
                      cursor: 'pointer',
                      whiteSpace: 'nowrap'
                    }}
                  >
                    <Plus size={15} /> Add Partner
                  </button>
                </div>
              </div>

              {/* Partner Data Table View */}
              {filteredPartners.length === 0 ? (
                <div className="glass-panel" style={{ padding: 60, textAlign: 'center', color: 'var(--text-muted)' }}>
                  <Briefcase size={42} color="#CBD5E1" style={{ margin: '0 auto 12px' }} />
                  <h4 style={{ fontSize: '1.1rem', fontWeight: 700, color: 'var(--text-main)' }}>No partners found</h4>
                  <p style={{ fontSize: '0.85rem', marginTop: 4 }}>Change filter tab or register a new service partner.</p>
                </div>
              ) : (
                <div className="glass-panel" style={{ padding: 0, overflow: 'hidden' }}>
                  <div style={{ overflowX: 'auto' }}>
                    <table style={{ width: '100%', minWidth: 1080, borderCollapse: 'collapse', textAlign: 'left', fontSize: '0.85rem' }}>
                      <thead>
                        <tr style={{ background: '#F8FAFC', borderBottom: '1px solid var(--border)' }}>
                          <th style={{ padding: '14px 20px', fontWeight: 700, color: 'var(--text-muted)', fontSize: '0.75rem', letterSpacing: '0.04em' }}>PARTNER NAME</th>
                          <th style={{ padding: '14px 16px', fontWeight: 700, color: 'var(--text-muted)', fontSize: '0.75rem', letterSpacing: '0.04em' }}>TRADE & SKILL</th>
                          <th style={{ padding: '14px 16px', fontWeight: 700, color: 'var(--text-muted)', fontSize: '0.75rem', letterSpacing: '0.04em' }}>CONTACT INFO</th>
                          <th style={{ padding: '14px 16px', fontWeight: 700, color: 'var(--text-muted)', fontSize: '0.75rem', letterSpacing: '0.04em' }}>AADHAAR / VEHICLE</th>
                          <th style={{ padding: '14px 16px', fontWeight: 700, color: 'var(--text-muted)', fontSize: '0.75rem', letterSpacing: '0.04em' }}>DUTY STATUS</th>
                          <th style={{ padding: '14px 16px', fontWeight: 700, color: 'var(--text-muted)', fontSize: '0.75rem', letterSpacing: '0.04em' }}>EARNINGS</th>
                          <th style={{ padding: '14px 16px', fontWeight: 700, color: 'var(--text-muted)', fontSize: '0.75rem', letterSpacing: '0.04em' }}>SUBSCRIPTION</th>
                          <th style={{ padding: '14px 16px', fontWeight: 700, color: 'var(--text-muted)', fontSize: '0.75rem', letterSpacing: '0.04em' }}>KYC STATUS</th>
                          <th style={{ padding: '14px 20px', fontWeight: 700, color: 'var(--text-muted)', fontSize: '0.75rem', letterSpacing: '0.04em', textAlign: 'right' }}>ACTIONS</th>
                        </tr>
                      </thead>
                      <tbody>
                        {filteredPartners.map((prov, idx) => (
                          <tr
                            key={prov.id}
                            style={{
                              borderBottom: '1px solid var(--border)',
                              background: prov.kycStatus === 'pending' ? '#FFFDF5' : idx % 2 === 0 ? '#FFFFFF' : '#FAFBFD',
                              transition: 'background 0.15s ease'
                            }}
                          >
                            {/* 1. Partner Name & Rating */}
                            <td style={{ padding: '14px 20px' }}>
                              <div style={{ display: 'flex', alignItems: 'center', gap: 12 }}>
                                <div style={{
                                  width: 38,
                                  height: 38,
                                  borderRadius: '50%',
                                  background: '#EFF6FF',
                                  border: '1.5px solid #BFDBFE',
                                  display: 'flex',
                                  alignItems: 'center',
                                  justifyContent: 'center',
                                  fontWeight: 700,
                                  fontSize: '0.95rem',
                                  color: '#2563EB',
                                  flexShrink: 0
                                }}>
                                  {prov.name ? prov.name.charAt(0).toUpperCase() : 'P'}
                                </div>
                                <div>
                                  <div style={{ display: 'flex', alignItems: 'center', gap: 6 }}>
                                    <span style={{ fontWeight: 700, color: 'var(--text-main)', fontSize: '0.9rem' }}>
                                      {prov.name}
                                    </span>
                                    <span style={{ display: 'inline-flex', alignItems: 'center', gap: 2, background: '#FEF9C3', color: '#854D0E', fontSize: '0.68rem', fontWeight: 700, padding: '1px 5px', borderRadius: 4 }}>
                                      <Star size={10} fill="#CA8A04" color="#CA8A04" /> {prov.rating || 5}
                                    </span>
                                  </div>
                                  <p style={{ fontSize: '0.72rem', color: 'var(--text-muted)', marginTop: 1, fontWeight: 600 }}>
                                    ID: <span style={{ color: '#2563EB' }}>{prov.partnerCode || (prov.id?.startsWith('prv_') ? `LP-${prov.id.slice(-4).toUpperCase()}` : prov.id)}</span>
                                  </p>
                                </div>
                              </div>
                            </td>

                            {/* 2. Trade & Skill */}
                            <td style={{ padding: '14px 16px' }}>
                              <div style={{ display: 'flex', flexDirection: 'column', gap: 3 }}>
                                <div style={{ display: 'inline-flex', alignItems: 'center', gap: 5, background: '#FFF4EF', padding: '2px 8px', borderRadius: 5, border: '1px solid #FFD3C2', width: 'fit-content' }}>
                                  {getCategoryIcon(prov.category)}
                                  <span style={{ fontSize: '0.72rem', fontWeight: 700, color: '#DE4915' }}>
                                    {prov.categoryName || (prov.category ? prov.category.replace('cat_', '').replace(/_/g, ' ') : 'General')}
                                  </span>
                                </div>
                                <span style={{ fontSize: '0.75rem', color: '#334155', fontWeight: 600 }}>
                                  ↳ {prov.subCategoryName || prov.serviceName || 'All Services'}
                                </span>
                                {prov.selectedChildServices && prov.selectedChildServices.length > 0 && (
                                  <span style={{ fontSize: '0.68rem', color: '#059669', background: '#ECFDF5', padding: '1px 6px', borderRadius: 4, width: 'fit-content', border: '1px solid #A7F3D0' }}>
                                    {prov.selectedChildServices.length} Selected Tasks
                                  </span>
                                )}
                              </div>
                            </td>

                            {/* 3. Phone & Email */}
                            <td style={{ padding: '14px 16px' }}>
                              <div style={{ display: 'flex', flexDirection: 'column', gap: 2 }}>
                                <span style={{ fontWeight: 600, color: 'var(--text-main)', display: 'flex', alignItems: 'center', gap: 6 }}>
                                  <Phone size={12} color="#DE4915" /> {prov.phone}
                                </span>
                                {prov.email && (
                                  <span style={{ fontSize: '0.74rem', color: 'var(--text-muted)' }}>
                                    {prov.email}
                                  </span>
                                )}
                              </div>
                            </td>

                            {/* 4. Aadhaar / Vehicle */}
                            <td style={{ padding: '14px 16px' }}>
                              <div style={{ display: 'flex', flexDirection: 'column', gap: 2 }}>
                                <span style={{ fontSize: '0.78rem', color: 'var(--text-main)', fontWeight: 600 }}>
                                  {prov.aadhaarNumber || 'Verified ID'}
                                </span>
                                {prov.vehicleNumber ? (
                                  <span style={{ fontSize: '0.72rem', color: 'var(--text-muted)' }}>
                                    Vehicle: <strong>{prov.vehicleNumber}</strong>
                                  </span>
                                ) : (
                                  <span style={{ fontSize: '0.72rem', color: 'var(--text-dim)' }}>
                                    Vehicle: <strong>N/A</strong>
                                  </span>
                                )}
                              </div>
                            </td>

                            {/* 5. Duty Status Toggle */}
                            <td style={{ padding: '14px 16px' }}>
                              <button
                                onClick={() => handleTogglePartnerOnline(prov.id)}
                                title={prov.isOnline ? 'Click to set Offline' : 'Click to set Online'}
                                style={{
                                  display: 'inline-flex',
                                  alignItems: 'center',
                                  gap: 6,
                                  padding: '4px 10px',
                                  borderRadius: 20,
                                  background: prov.isOnline ? '#ECFDF5' : '#F1F5F9',
                                  border: prov.isOnline ? '1px solid #A7F3D0' : '1px solid #CBD5E1',
                                  color: prov.isOnline ? '#059669' : '#64748B',
                                  fontSize: '0.72rem',
                                  fontWeight: 700,
                                  cursor: 'pointer',
                                  transition: 'all 0.15s ease'
                                }}
                              >
                                <span style={{ width: 7, height: 7, borderRadius: '50%', background: prov.isOnline ? '#10B981' : '#94A3B8' }} />
                                {prov.isOnline ? 'ON DUTY' : 'OFFLINE'}
                              </button>
                            </td>

                            {/* 6. Earnings & Jobs */}
                            <td style={{ padding: '14px 16px' }}>
                              <div style={{ display: 'flex', flexDirection: 'column', gap: 2 }}>
                                <span style={{ fontWeight: 700, color: '#059669', fontSize: '0.88rem' }}>
                                  ₹{prov.earnings ?? prov.walletBalance ?? 0}
                                </span>
                                <span style={{ fontSize: '0.72rem', color: 'var(--text-muted)' }}>
                                  {prov.completedJobs ?? 0} completed jobs
                                </span>
                              </div>
                            </td>

                            {/* 7. Subscription Column */}
                            <td style={{ padding: '14px 16px' }}>
                              <div style={{ display: 'flex', flexDirection: 'column', gap: 4 }}>
                                {prov.subscriptionStatus === 'active' ? (
                                  <div>
                                    <span style={{
                                      display: 'inline-flex',
                                      alignItems: 'center',
                                      gap: 4,
                                      background: '#ECFDF5',
                                      color: '#059669',
                                      border: '1px solid #A7F3D0',
                                      padding: '2px 8px',
                                      borderRadius: 5,
                                      fontSize: '0.72rem',
                                      fontWeight: 700
                                    }}>
                                      <CheckCircle2 size={11} /> {prov.subscriptionPlanName || 'Active (0% cut)'}
                                    </span>
                                    {prov.subscriptionExpiresAt && (
                                      <p style={{ fontSize: '0.67rem', color: 'var(--text-muted)', marginTop: 2 }}>
                                        Till: {new Date(prov.subscriptionExpiresAt).toLocaleDateString()}
                                      </p>
                                    )}
                                  </div>
                                ) : (
                                  <div style={{ display: 'flex', flexDirection: 'column', gap: 3 }}>
                                    <span style={{
                                      display: 'inline-flex',
                                      alignItems: 'center',
                                      gap: 4,
                                      background: '#FEF2F2',
                                      color: '#DC2626',
                                      border: '1px solid #FECACA',
                                      padding: '2px 8px',
                                      borderRadius: 5,
                                      fontSize: '0.72rem',
                                      fontWeight: 700,
                                      width: 'fit-content'
                                    }}>
                                      Unpaid
                                    </span>
                                    {(() => {
                                      const cat = categories.find(c => c.id === prov.category);
                                      const sub = cat?.subCategories?.find(s => s.id === (prov.subCategoryId || prov.subCategory));
                                      const yrRate = sub?.subscriptionPlans?.['1_year'] || 1499;

                                      return (
                                        <button
                                          onClick={() => handleOpenPaySubModal(prov)}
                                          title="Record Payment & Activate Subscription for this Sub-Category"
                                          style={{
                                            background: '#F97316',
                                            color: '#fff',
                                            border: 'none',
                                            padding: '4px 8px',
                                            borderRadius: 5,
                                            fontSize: '0.7rem',
                                            fontWeight: 700,
                                            cursor: 'pointer',
                                            display: 'inline-flex',
                                            alignItems: 'center',
                                            gap: 4,
                                            boxShadow: '0 1px 3px rgba(249,115,22,0.3)'
                                          }}
                                        >
                                          💳 Mark Paid (₹{yrRate})
                                        </button>
                                      );
                                    })()}
                                  </div>
                                )}
                              </div>
                            </td>

                            {/* 8. KYC Status & Actions */}
                            <td style={{ padding: '14px 16px' }}>
                              {prov.kycStatus === 'verified' || prov.kycStatus === 'approved' ? (
                                <span style={{
                                  display: 'inline-flex',
                                  alignItems: 'center',
                                  gap: 4,
                                  background: '#ECFDF5',
                                  color: '#059669',
                                  border: '1px solid #A7F3D0',
                                  padding: '3px 8px',
                                  borderRadius: 6,
                                  fontSize: '0.74rem',
                                  fontWeight: 700
                                }}>
                                  <CheckCircle2 size={12} /> Approved
                                </span>
                              ) : (
                                <div style={{ display: 'flex', alignItems: 'center', gap: 6 }}>
                                  <span style={{
                                    background: '#FFFBEB',
                                    color: '#D97706',
                                    border: '1px solid #FCD34D',
                                    padding: '3px 6px',
                                    borderRadius: 5,
                                    fontSize: '0.7rem',
                                    fontWeight: 700
                                  }}>
                                    Pending
                                  </span>
                                  <button
                                    onClick={() => handleKycStatus(prov.id, 'verified')}
                                    title="Approve KYC"
                                    style={{
                                      background: '#059669',
                                      color: '#fff',
                                      border: 'none',
                                      padding: '3px 7px',
                                      borderRadius: 5,
                                      fontSize: '0.7rem',
                                      fontWeight: 700,
                                      cursor: 'pointer'
                                    }}
                                  >
                                    ✓ Approve
                                  </button>
                                  <button
                                    onClick={() => handleKycStatus(prov.id, 'rejected')}
                                    title="Reject KYC"
                                    style={{
                                      background: '#EF4444',
                                      color: '#fff',
                                      border: 'none',
                                      padding: '3px 6px',
                                      borderRadius: 5,
                                      fontSize: '0.7rem',
                                      fontWeight: 700,
                                      cursor: 'pointer'
                                    }}
                                  >
                                    ✕
                                  </button>
                                </div>
                              )}
                            </td>

                            {/* 8. Actions */}
                            <td style={{ padding: '14px 20px', textAlign: 'right' }}>
                              <button
                                onClick={() => handleDeletePartner(prov.id, prov.name)}
                                title="Remove Partner"
                                style={{
                                  background: '#FEF2F2',
                                  border: '1px solid #FECACA',
                                  color: '#DC2626',
                                  padding: '6px 9px',
                                  borderRadius: 6,
                                  cursor: 'pointer',
                                  display: 'inline-flex',
                                  alignItems: 'center',
                                  gap: 4,
                                  fontSize: '0.75rem',
                                  fontWeight: 600
                                }}
                              >
                                <Trash2 size={13} /> Delete
                              </button>
                            </td>
                          </tr>
                        ))}
                      </tbody>
                    </table>
                  </div>

                  {/* Table Footer */}
                  <div style={{
                    padding: '12px 20px',
                    background: '#F8FAFC',
                    borderTop: '1px solid var(--border)',
                    display: 'flex',
                    alignItems: 'center',
                    justifyContent: 'space-between',
                    fontSize: '0.78rem',
                    color: 'var(--text-muted)'
                  }}>
                    <span>Total <strong>{filteredPartners.length}</strong> partners in fleet</span>
                    <span>Click 'ON DUTY' button in row to toggle availability</span>
                  </div>
                </div>
              )}
            </div>
          )}

          {/* TAB 6: ADS & PROMOTIONS MANAGEMENT */}
          {activeTab === 'promotions' && (
            <div style={{ display: 'flex', flexDirection: 'column', gap: 24 }}>
              {/* Metric KPI Cards */}
              <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(220px, 1fr))', gap: 18 }}>
                <div className="glass-panel" style={{ padding: '20px' }}>
                  <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start' }}>
                    <p style={{ fontSize: '0.8rem', color: 'var(--text-muted)', fontWeight: 600 }}>LIVE ACTIVE ADS</p>
                    <div style={{ width: 36, height: 36, borderRadius: 10, background: '#FFF4EF', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
                      <Megaphone size={19} color="#DE4915" />
                    </div>
                  </div>
                  <h3 style={{ fontSize: '1.8rem', fontWeight: 800, marginTop: 10, color: 'var(--text-main)' }}>
                    {promotions.filter(p => p.active).length}
                  </h3>
                  <p style={{ fontSize: '0.75rem', color: '#DE4915', fontWeight: 600, marginTop: 8 }}>
                    Active out of {promotions.length} total ads
                  </p>
                </div>

                <div className="glass-panel" style={{ padding: '20px' }}>
                  <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start' }}>
                    <p style={{ fontSize: '0.8rem', color: 'var(--text-muted)', fontWeight: 600 }}>SPOTLIGHT BILLBOARDS</p>
                    <div style={{ width: 36, height: 36, borderRadius: 10, background: '#FEF3C7', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
                      <Star size={19} color="#D97706" />
                    </div>
                  </div>
                  <h3 style={{ fontSize: '1.8rem', fontWeight: 800, marginTop: 10, color: '#D97706' }}>
                    {promotions.filter(p => p.type === 'spotlight' && p.active).length}
                  </h3>
                  <p style={{ fontSize: '0.75rem', color: '#D97706', fontWeight: 600, marginTop: 8 }}>
                    Grand Openings & Gold Showrooms
                  </p>
                </div>

                <div className="glass-panel" style={{ padding: '20px' }}>
                  <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start' }}>
                    <p style={{ fontSize: '0.8rem', color: 'var(--text-muted)', fontWeight: 600 }}>SPONSORED DEALS</p>
                    <div style={{ width: 36, height: 36, borderRadius: 10, background: '#EFF6FF', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
                      <Tag size={19} color="#2563EB" />
                    </div>
                  </div>
                  <h3 style={{ fontSize: '1.8rem', fontWeight: 800, marginTop: 10, color: '#2563EB' }}>
                    {promotions.filter(p => p.type === 'deal' && p.active).length}
                  </h3>
                  <p style={{ fontSize: '0.75rem', color: '#2563EB', fontWeight: 600, marginTop: 8 }}>
                    Discounts & Instant Fix Banners
                  </p>
                </div>

                <div className="glass-panel" style={{ padding: '20px' }}>
                  <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start' }}>
                    <p style={{ fontSize: '0.8rem', color: 'var(--text-muted)', fontWeight: 600 }}>LOGIN POPUP SCREENS</p>
                    <div style={{ width: 36, height: 36, borderRadius: 10, background: '#FCE7F3', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
                      <Sparkles size={19} color="#BE185D" />
                    </div>
                  </div>
                  <h3 style={{ fontSize: '1.8rem', fontWeight: 800, marginTop: 10, color: '#BE185D' }}>
                    {promotions.filter(p => p.type === 'popup' && p.active).length}
                  </h3>
                  <p style={{ fontSize: '0.75rem', color: '#BE185D', fontWeight: 600, marginTop: 8 }}>
                    Full Screen Store Launch Promos
                  </p>
                </div>
              </div>

              {/* Toolbar: Format Filter Pills & Search */}
              <div className="glass-panel" style={{ padding: '16px 20px', display: 'flex', flexWrap: 'wrap', alignItems: 'center', justifyContent: 'space-between', gap: 14 }}>
                <div style={{ display: 'flex', flexWrap: 'wrap', gap: 8 }}>
                  {[
                    { key: 'all', label: `All Ads (${promotions.length})` },
                    { key: 'spotlight', label: `🌟 Spotlight Billboards (${promotions.filter(p => p.type === 'spotlight').length})` },
                    { key: 'deal', label: `🏷️ Sponsored Deals (${promotions.filter(p => p.type === 'deal').length})` },
                    { key: 'popup', label: `🛍️ Login Popups (${promotions.filter(p => p.type === 'popup').length})` },
                    { key: 'hero', label: `🚀 Hero Banners (${promotions.filter(p => p.type === 'hero').length})` }
                  ].map(tab => (
                    <button
                      key={tab.key}
                      onClick={() => setPromoTypeFilter(tab.key)}
                      style={{
                        padding: '6px 14px',
                        borderRadius: 20,
                        border: promoTypeFilter === tab.key ? '1px solid #FFD3C2' : '1px solid #E2E8F0',
                        background: promoTypeFilter === tab.key ? '#FFF4EF' : '#F8FAFC',
                        color: promoTypeFilter === tab.key ? '#DE4915' : '#64748B',
                        fontWeight: promoTypeFilter === tab.key ? 700 : 500,
                        fontSize: '0.8rem',
                        cursor: 'pointer',
                        transition: 'all 0.15s ease'
                      }}
                    >
                      {tab.label}
                    </button>
                  ))}
                </div>

                <div style={{ display: 'flex', alignItems: 'center', gap: 10, minWidth: 260 }}>
                  <div style={{ position: 'relative', width: '100%' }}>
                    <Search size={15} color="#94A3B8" style={{ position: 'absolute', left: 12, top: 10 }} />
                    <input
                      type="text"
                      placeholder="Search ads by name, store, offer..."
                      value={promoSearch}
                      onChange={(e) => setPromoSearch(e.target.value)}
                      style={{
                        width: '100%',
                        padding: '8px 14px 8px 34px',
                        borderRadius: 8,
                        border: '1px solid #CBD5E1',
                        fontSize: '0.82rem',
                        outline: 'none',
                        background: '#fff'
                      }}
                    />
                  </div>
                </div>
              </div>

              {/* Ad Cards Grid */}
              {filteredPromotions.length === 0 ? (
                <div className="glass-panel" style={{ padding: '60px 20px', textAlign: 'center' }}>
                  <Megaphone size={42} color="#CBD5E1" style={{ margin: '0 auto 14px' }} />
                  <h3 style={{ fontSize: '1.1rem', fontWeight: 700, color: '#334155' }}>No Advertisements Found</h3>
                  <p style={{ fontSize: '0.82rem', color: '#64748B', marginTop: 4 }}>
                    Try changing your filter or create a new ad banner for the Customer App.
                  </p>
                  <button
                    onClick={() => {
                      resetPromoForm();
                      setShowPromoModal(true);
                    }}
                    style={{
                      marginTop: 16,
                      background: '#DE4915',
                      color: '#fff',
                      padding: '8px 16px',
                      borderRadius: 8,
                      border: 'none',
                      fontWeight: 600,
                      cursor: 'pointer'
                    }}
                  >
                    + Create First Ad
                  </button>
                </div>
              ) : (
                <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fill, minmax(360px, 1fr))', gap: 20 }}>
                  {filteredPromotions.map(promo => {
                    const isSpotlight = promo.type === 'spotlight';
                    const isDeal = promo.type === 'deal';
                    const isPopup = promo.type === 'popup';
                    const isHero = promo.type === 'hero';

                    const typeBadgeColor = isSpotlight ? '#D97706' : isDeal ? '#2563EB' : isPopup ? '#BE185D' : '#059669';
                    const typeBadgeBg = isSpotlight ? '#FEF3C7' : isDeal ? '#EFF6FF' : isPopup ? '#FCE7F3' : '#ECFDF5';
                    const typeLabel = isSpotlight ? 'SPOTLIGHT BILLBOARD' : isDeal ? 'SPONSORED DEAL' : isPopup ? 'LOGIN POPUP SCREEN' : 'TOP HERO BANNER';

                    return (
                      <div
                        key={promo.id}
                        className="glass-panel"
                        style={{
                          borderRadius: 14,
                          overflow: 'hidden',
                          border: '1px solid var(--border)',
                          display: 'flex',
                          flexDirection: 'column',
                          background: '#fff',
                          boxShadow: '0 4px 14px rgba(0,0,0,0.03)'
                        }}
                      >
                        {/* Card Image Header with Badges */}
                        <div style={{ position: 'relative', height: 160, background: '#0F172A', overflow: 'hidden' }}>
                          <img
                            src={promo.imageUrl || 'https://images.unsplash.com/photo-1610030469983-98e550d6193c?w=900&auto=format&fit=crop&q=80'}
                            alt={promo.title}
                            style={{ width: '100%', height: '100%', objectFit: 'cover' }}
                            onError={(e) => {
                              e.target.style.display = 'none';
                            }}
                          />
                          <div style={{
                            position: 'absolute',
                            inset: 0,
                            background: 'linear-gradient(to bottom, rgba(0,0,0,0.2) 0%, rgba(0,0,0,0.75) 100%)'
                          }} />

                          {/* Top-Left Type Badge */}
                          <div style={{
                            position: 'absolute',
                            top: 12,
                            left: 12,
                            padding: '4px 9px',
                            borderRadius: 12,
                            background: typeBadgeBg,
                            color: typeBadgeColor,
                            fontSize: '0.68rem',
                            fontWeight: 800,
                            letterSpacing: '0.04em'
                          }}>
                            {typeLabel}
                          </div>

                          {/* Top-Right Active Toggle Switch */}
                          <button
                            onClick={() => handleTogglePromoActive(promo.id)}
                            title="Click to toggle Active / Paused"
                            style={{
                              position: 'absolute',
                              top: 10,
                              right: 12,
                              padding: '4px 10px',
                              borderRadius: 20,
                              background: promo.active ? 'rgba(16, 185, 129, 0.95)' : 'rgba(100, 116, 139, 0.85)',
                              color: '#fff',
                              border: 'none',
                              fontSize: '0.72rem',
                              fontWeight: 800,
                              cursor: 'pointer',
                              display: 'flex',
                              alignItems: 'center',
                              gap: 5,
                              boxShadow: '0 2px 6px rgba(0,0,0,0.2)'
                            }}
                          >
                            <span style={{ width: 6, height: 6, borderRadius: '50%', background: '#fff' }} />
                            {promo.active ? 'ACTIVE' : 'PAUSED'}
                          </button>

                          {/* Bottom Headline on Image */}
                          <div style={{ position: 'absolute', bottom: 12, left: 14, right: 14 }}>
                            <span style={{ fontSize: '0.68rem', fontWeight: 800, color: '#FCD34D', textTransform: 'uppercase' }}>
                              {promo.tag || promo.badge}
                            </span>
                            <h4 style={{ color: '#fff', fontSize: '1.05rem', fontWeight: 800, margin: '2px 0 0', textShadow: '0 1px 3px rgba(0,0,0,0.6)' }}>
                              {promo.title || promo.storeName}
                            </h4>
                          </div>
                        </div>

                        {/* Card Body */}
                        <div style={{ padding: '16px', display: 'flex', flexDirection: 'column', gap: 10, flex: 1 }}>
                          {/* Offer Banner */}
                          {promo.offer && (
                            <div style={{
                              padding: '8px 12px',
                              borderRadius: 8,
                              background: '#FFF1F2',
                              border: '1px solid #FECDD3',
                              color: '#9F1239',
                              fontWeight: 800,
                              fontSize: '0.85rem',
                              display: 'flex',
                              alignItems: 'center',
                              justifyContent: 'space-between'
                            }}>
                              <span>🔥 {promo.offer}</span>
                              {promo.promoCode && (
                                <span style={{
                                  background: '#fff',
                                  padding: '2px 6px',
                                  borderRadius: 4,
                                  border: '1px dashed #BE123C',
                                  fontSize: '0.72rem',
                                  fontFamily: 'monospace'
                                }}>
                                  {promo.promoCode}
                                </span>
                              )}
                            </div>
                          )}

                          {/* Description / Subtitle */}
                          <p style={{
                            fontSize: '0.78rem',
                            color: '#475569',
                            margin: 0,
                            lineHeight: 1.4,
                            display: '-webkit-box',
                            WebkitLineClamp: 2,
                            WebkitBoxOrient: 'vertical',
                            overflow: 'hidden'
                          }}>
                            {promo.description || promo.subtitle || 'Active marketing banner campaign on Loki Customer App.'}
                          </p>

                          {/* Location & CTA info */}
                          <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', fontSize: '0.74rem', color: '#64748B', marginTop: 'auto', paddingTop: 6 }}>
                            <span style={{ display: 'flex', alignItems: 'center', gap: 4, overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>
                              <MapPin size={13} color="#DE4915" />
                              {promo.location || 'All Hyderabad Localities'}
                            </span>
                            <span style={{ fontWeight: 700, color: '#DE4915' }}>
                              CTA: {promo.cta || 'Explore'}
                            </span>
                          </div>

                          {/* Impressions & Clicks Stat Pill */}
                          <div style={{
                            padding: '6px 10px',
                            background: '#F8FAFC',
                            borderRadius: 6,
                            fontSize: '0.72rem',
                            color: '#64748B',
                            display: 'flex',
                            alignItems: 'center',
                            justifyContent: 'space-between',
                            border: '1px solid #F1F5F9'
                          }}>
                            <span>Views: <strong>{promo.impressions || 120}</strong></span>
                            <span>Clicks: <strong>{promo.clicks || 34}</strong></span>
                            <span>Priority: <strong>#{promo.priority || 1}</strong></span>
                          </div>

                          {/* Action Buttons: Edit & Delete */}
                          <div style={{ display: 'flex', gap: 8, marginTop: 4, borderTop: '1px solid #F1F5F9', paddingTop: 10 }}>
                            <button
                              onClick={() => handleEditPromo(promo)}
                              style={{
                                flex: 1,
                                padding: '7px 0',
                                borderRadius: 6,
                                background: '#F8FAFC',
                                border: '1px solid #CBD5E1',
                                color: '#334155',
                                fontWeight: 600,
                                fontSize: '0.78rem',
                                cursor: 'pointer',
                                display: 'flex',
                                alignItems: 'center',
                                justifyContent: 'center',
                                gap: 6
                              }}
                            >
                              <Edit2 size={13} /> Edit Ad
                            </button>
                            <button
                              onClick={() => handleDeletePromo(promo.id, promo.title || promo.storeName)}
                              style={{
                                padding: '7px 12px',
                                borderRadius: 6,
                                background: '#FEF2F2',
                                border: '1px solid #FECACA',
                                color: '#DC2626',
                                fontWeight: 600,
                                fontSize: '0.78rem',
                                cursor: 'pointer',
                                display: 'flex',
                                alignItems: 'center',
                                justifyContent: 'center',
                                gap: 4
                              }}
                            >
                              <Trash2 size={13} /> Delete
                            </button>
                          </div>
                        </div>
                      </div>
                    );
                  })}
                </div>
              )}
            </div>
          )}
        </div>
      </main>

      {/* 1. MODAL: ADD / EDIT CATEGORY WITH ICON UPLOAD */}
      {showAddCatModal && (
        <div style={{
          position: 'fixed',
          top: 0,
          left: 0,
          right: 0,
          bottom: 0,
          background: 'rgba(15, 23, 42, 0.55)',
          backdropFilter: 'blur(6px)',
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'center',
          zIndex: 1100,
          padding: 20
        }}>
          <div className="glass-panel" style={{ width: 460, maxWidth: '100%', padding: 26, background: '#FFFFFF', borderRadius: 16, boxShadow: '0 25px 50px -12px rgba(0, 0, 0, 0.25)', border: '1px solid #E2E8F0' }}>
            <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: 14 }}>
              <div>
                <h3 style={{ fontSize: '1.2rem', fontWeight: 800, color: 'var(--text-main)', margin: 0 }}>
                  {editingCategory ? 'Edit Category & Icon' : 'Add New Category'}
                </h3>
                <p style={{ margin: '4px 0 0', fontSize: '0.78rem', color: 'var(--text-muted)' }}>
                  Upload custom icon & assign theme color. Instantly syncs with Customer App.
                </p>
              </div>
              <button
                type="button"
                onClick={() => { setShowAddCatModal(false); resetCatInputs(); }}
                style={{ background: '#F1F5F9', border: 'none', borderRadius: '50%', width: 30, height: 30, cursor: 'pointer', fontSize: '1rem', color: '#64748B' }}
              >
                ✕
              </button>
            </div>

            <form onSubmit={handleSaveCategory} style={{ display: 'flex', flexDirection: 'column', gap: 16 }}>
              {/* Category Name */}
              <div>
                <label style={{ fontSize: '0.8rem', color: 'var(--text-main)', fontWeight: 700 }}>
                  Category Name *
                </label>
                <input
                  type="text"
                  placeholder="e.g. Salon & Beauty, Home Cleaning, Painting..."
                  autoFocus
                  required
                  value={catNameInput}
                  onChange={(e) => setCatNameInput(e.target.value)}
                  style={{ width: '100%', padding: '10px 14px', marginTop: 6, borderRadius: 8, background: '#F8FAFC', color: 'var(--text-main)', border: '1px solid #CBD5E1', outline: 'none', fontSize: '0.9rem', fontWeight: 600 }}
                />
              </div>

              {/* Category Icon / Image Upload */}
              <div>
                <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: 6 }}>
                  <label style={{ fontSize: '0.8rem', color: 'var(--text-main)', fontWeight: 700 }}>
                    Category Icon / Image (PNG / SVG / JPG)
                  </label>
                  {catUploading && (
                    <span style={{ fontSize: '0.72rem', color: '#DE4915', fontWeight: 700 }}>
                      Uploading image...
                    </span>
                  )}
                </div>

                {catIconPreview || catIconUrlInput ? (
                  <div style={{
                    display: 'flex',
                    alignItems: 'center',
                    gap: 14,
                    padding: 12,
                    borderRadius: 10,
                    background: '#F8FAFC',
                    border: '1.5px solid #CBD5E1'
                  }}>
                    <div style={{
                      width: 54,
                      height: 54,
                      borderRadius: 12,
                      background: catColorInput || '#DE4915',
                      display: 'flex',
                      alignItems: 'center',
                      justifyContent: 'center',
                      flexShrink: 0,
                      boxShadow: '0 4px 10px rgba(0,0,0,0.1)'
                    }}>
                      <img
                        src={catIconPreview || catIconUrlInput}
                        alt="Icon Preview"
                        style={{ width: 34, height: 34, objectFit: 'contain' }}
                        onError={(e) => { e.target.style.display = 'none'; }}
                      />
                    </div>
                    <div style={{ flex: 1, overflow: 'hidden' }}>
                      <p style={{ margin: 0, fontSize: '0.82rem', fontWeight: 700, color: '#059669', display: 'flex', alignItems: 'center', gap: 4 }}>
                        <Check size={14} /> Icon Ready
                      </p>
                      <p style={{ margin: '3px 0 0', fontSize: '0.7rem', color: '#64748B', whiteSpace: 'nowrap', textOverflow: 'ellipsis', overflow: 'hidden' }}>
                        {catIconUrlInput.startsWith('data:') ? 'Custom uploaded image (embedded)' : catIconUrlInput}
                      </p>
                    </div>
                    <div style={{ display: 'flex', gap: 6 }}>
                      <label style={{
                        padding: '6px 10px',
                        borderRadius: 6,
                        background: '#FFFFFF',
                        border: '1px solid #CBD5E1',
                        color: 'var(--text-main)',
                        fontSize: '0.73rem',
                        fontWeight: 600,
                        cursor: 'pointer'
                      }}>
                        Change
                        <input
                          type="file"
                          accept="image/*"
                          onChange={handleCategoryIconUpload}
                          style={{ display: 'none' }}
                        />
                      </label>
                      <button
                        type="button"
                        onClick={() => { setCatIconUrlInput(''); setCatIconPreview(''); }}
                        style={{
                          padding: '6px 8px',
                          borderRadius: 6,
                          background: '#FEF2F2',
                          border: '1px solid #FECACA',
                          color: '#DC2626',
                          fontSize: '0.73rem',
                          fontWeight: 600,
                          cursor: 'pointer'
                        }}
                      >
                        Remove
                      </button>
                    </div>
                  </div>
                ) : (
                  <label style={{
                    display: 'flex',
                    flexDirection: 'column',
                    alignItems: 'center',
                    justifyContent: 'center',
                    padding: '20px 14px',
                    borderRadius: 10,
                    background: '#F8FAFC',
                    border: '2px dashed #CBD5E1',
                    cursor: 'pointer',
                    transition: 'all 0.15s ease'
                  }}>
                    <UploadCloud size={28} color="#94A3B8" />
                    <span style={{ fontSize: '0.84rem', fontWeight: 700, color: '#334155', marginTop: 6 }}>
                      Click to Upload Custom Icon / Image
                    </span>
                    <span style={{ fontSize: '0.72rem', color: '#94A3B8', marginTop: 2 }}>
                      PNG, SVG, JPG, WebP (Transparent icons look best in Customer App)
                    </span>
                    <input
                      type="file"
                      accept="image/*"
                      onChange={handleCategoryIconUpload}
                      style={{ display: 'none' }}
                    />
                  </label>
                )}

                {/* Direct Image URL input option */}
                <div style={{ marginTop: 8 }}>
                  <input
                    type="url"
                    placeholder="...or paste direct image URL (https://.../icon.png)"
                    value={catIconUrlInput}
                    onChange={(e) => {
                      setCatIconUrlInput(e.target.value);
                      setCatIconPreview(e.target.value);
                    }}
                    style={{
                      width: '100%',
                      padding: '7px 10px',
                      borderRadius: 6,
                      background: '#FFFFFF',
                      border: '1px solid #E2E8F0',
                      fontSize: '0.76rem',
                      color: '#475569',
                      outline: 'none'
                    }}
                  />
                </div>
              </div>

              {/* Theme Color Swatch */}
              <div>
                <label style={{ display: 'block', fontSize: '0.8rem', color: 'var(--text-main)', fontWeight: 700, marginBottom: 8 }}>
                  Category Theme Color:
                </label>
                <div style={{ display: 'flex', gap: 8, alignItems: 'center', flexWrap: 'wrap' }}>
                  {[
                    { hex: '#DE4915', name: 'Loki Orange' },
                    { hex: '#2563EB', name: 'Royal Blue' },
                    { hex: '#10B981', name: 'Emerald' },
                    { hex: '#F59E0B', name: 'Amber Gold' },
                    { hex: '#8B5CF6', name: 'Purple' },
                    { hex: '#EC4899', name: 'Pink' },
                    { hex: '#EF4444', name: 'Red' },
                    { hex: '#06B6D4', name: 'Cyan' },
                  ].map(c => {
                    const isSelected = catColorInput.toLowerCase() === c.hex.toLowerCase();
                    return (
                      <div
                        key={c.hex}
                        onClick={() => setCatColorInput(c.hex)}
                        title={c.name}
                        style={{
                          width: 32,
                          height: 32,
                          borderRadius: 8,
                          background: c.hex,
                          cursor: 'pointer',
                          display: 'flex',
                          alignItems: 'center',
                          justifyContent: 'center',
                          border: isSelected ? '3px solid #1E293B' : '2px solid #FFFFFF',
                          boxShadow: isSelected ? '0 0 0 2px #DE4915' : '0 2px 5px rgba(0,0,0,0.1)',
                          transition: 'all 0.15s ease'
                        }}
                      >
                        {isSelected && <Check size={16} color="#FFFFFF" />}
                      </div>
                    );
                  })}
                </div>
              </div>

              {/* Actions */}
              <div style={{ display: 'flex', gap: 10, marginTop: 10 }}>
                <button
                  type="button"
                  onClick={() => { setShowAddCatModal(false); resetCatInputs(); }}
                  style={{ flex: 1, padding: '11px', borderRadius: 8, background: '#F1F5F9', color: 'var(--text-muted)', fontWeight: 600, cursor: 'pointer', border: 'none' }}
                >
                  Cancel
                </button>
                <button
                  type="submit"
                  disabled={catUploading}
                  style={{
                    flex: 1.5,
                    padding: '11px',
                    borderRadius: 8,
                    background: 'linear-gradient(135deg, #DE4915 0%, #B8350B 100%)',
                    color: '#fff',
                    fontWeight: 700,
                    cursor: catUploading ? 'wait' : 'pointer',
                    boxShadow: '0 4px 14px rgba(222, 73, 21, 0.3)',
                    border: 'none',
                    opacity: catUploading ? 0.7 : 1
                  }}
                >
                  {editingCategory ? 'Update Category' : 'Save & Publish Category'}
                </button>
              </div>
            </form>
          </div>
        </div>
      )}

      {/* 2. SIMPLE MODAL: ADD SUB-CATEGORY */}
      {showAddSubModal && (
        <div style={{
          position: 'fixed',
          top: 0,
          left: 0,
          right: 0,
          bottom: 0,
          background: 'rgba(15, 23, 42, 0.45)',
          backdropFilter: 'blur(6px)',
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'center',
          zIndex: 100
        }}>
          <div className="glass-panel" style={{ width: 420, padding: 26, background: '#FFFFFF', boxShadow: '0 20px 40px rgba(0,0,0,0.12)' }}>
            <h3 style={{ fontSize: '1.2rem', fontWeight: 700, color: 'var(--text-main)', marginBottom: 4 }}>
              Add Sub-Category
            </h3>
            <p style={{ fontSize: '0.82rem', color: '#DE4915', marginBottom: 16, fontWeight: 600 }}>
              Under: <strong>{targetCat?.name}</strong>
            </p>
            <form onSubmit={handleAddSubCategory} style={{ display: 'flex', flexDirection: 'column', gap: 14 }}>
              <div>
                <label style={{ fontSize: '0.8rem', color: 'var(--text-muted)', fontWeight: 600 }}>Sub-Category Name</label>
                <input
                  type="text"
                  placeholder="e.g. AC Services, Bathroom Cleaning..."
                  autoFocus
                  required
                  value={subNameInput}
                  onChange={(e) => setSubNameInput(e.target.value)}
                  style={{ width: '100%', padding: '11px 14px', marginTop: 6, borderRadius: 8, background: '#F8FAFC', color: 'var(--text-main)', border: '1px solid #CBD5E1', outline: 'none', fontSize: '0.9rem' }}
                />
              </div>

              <div style={{ display: 'flex', gap: 10, marginTop: 10 }}>
                <button
                  type="button"
                  onClick={() => setShowAddSubModal(false)}
                  style={{ flex: 1, padding: '10px', borderRadius: 8, background: '#F1F5F9', color: 'var(--text-muted)', fontWeight: 600, cursor: 'pointer' }}
                >
                  Cancel
                </button>
                <button
                  type="submit"
                  style={{ flex: 1, padding: '10px', borderRadius: 8, background: 'var(--primary)', color: '#fff', fontWeight: 600, cursor: 'pointer', boxShadow: '0 2px 10px rgba(222, 73, 21, 0.25)' }}
                >
                  Save Sub-Category
                </button>
              </div>
            </form>
          </div>
        </div>
      )}

      {/* 3. SIMPLE MODAL: ADD CHILD-CATEGORY */}
      {showAddChildModal && (
        <div style={{
          position: 'fixed',
          top: 0,
          left: 0,
          right: 0,
          bottom: 0,
          background: 'rgba(15, 23, 42, 0.45)',
          backdropFilter: 'blur(6px)',
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'center',
          zIndex: 100
        }}>
          <div className="glass-panel" style={{ width: 420, padding: 26, background: '#FFFFFF', boxShadow: '0 20px 40px rgba(0,0,0,0.12)' }}>
            <h3 style={{ fontSize: '1.2rem', fontWeight: 700, color: 'var(--text-main)', marginBottom: 4 }}>
              Add Child Category
            </h3>
            <p style={{ fontSize: '0.82rem', color: '#059669', marginBottom: 16, fontWeight: 600 }}>
              Under: <strong>{targetCat?.name}</strong> ➔ <strong>{targetSub?.name}</strong>
            </p>
            <form onSubmit={handleAddChildCategory} style={{ display: 'flex', flexDirection: 'column', gap: 14 }}>
              <div>
                <label style={{ fontSize: '0.8rem', color: 'var(--text-muted)', fontWeight: 600 }}>Child Category Name</label>
                <input
                  type="text"
                  placeholder="e.g. Split AC Deep Clean, Tap Repair..."
                  autoFocus
                  required
                  value={childNameInput}
                  onChange={(e) => setChildNameInput(e.target.value)}
                  style={{ width: '100%', padding: '11px 14px', marginTop: 6, borderRadius: 8, background: '#F8FAFC', color: 'var(--text-main)', border: '1px solid #CBD5E1', outline: 'none', fontSize: '0.9rem' }}
                />
              </div>

              <div style={{ display: 'flex', gap: 10, marginTop: 10 }}>
                <button
                  type="button"
                  onClick={() => setShowAddChildModal(false)}
                  style={{ flex: 1, padding: '10px', borderRadius: 8, background: '#F1F5F9', color: 'var(--text-muted)', fontWeight: 600, cursor: 'pointer' }}
                >
                  Cancel
                </button>
                <button
                  type="submit"
                  style={{ flex: 1, padding: '10px', borderRadius: 8, background: '#059669', color: '#fff', fontWeight: 600, cursor: 'pointer', boxShadow: '0 2px 10px rgba(5, 150, 105, 0.25)' }}
                >
                  Save Child Category
                </button>
              </div>
            </form>
          </div>
        </div>
      )}

      {/* 4. MODAL: ADD DISTRICT */}
      {showAddDistrictModal && (
        <div style={{
          position: 'fixed',
          top: 0,
          left: 0,
          right: 0,
          bottom: 0,
          background: 'rgba(15, 23, 42, 0.45)',
          backdropFilter: 'blur(6px)',
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'center',
          zIndex: 100
        }}>
          <div className="glass-panel" style={{ width: 420, padding: 26, background: '#FFFFFF', boxShadow: '0 20px 40px rgba(0,0,0,0.12)' }}>
            <h3 style={{ fontSize: '1.2rem', fontWeight: 700, color: 'var(--text-main)', marginBottom: 16 }}>
              Add District
            </h3>
            <form onSubmit={handleCreateDistrict} style={{ display: 'flex', flexDirection: 'column', gap: 14 }}>
              <div>
                <label style={{ fontSize: '0.8rem', color: 'var(--text-muted)', fontWeight: 600 }}>District Name</label>
                <input
                  type="text"
                  placeholder="e.g. Hyderabad, Rangareddy, Warangal..."
                  autoFocus
                  required
                  value={districtNameInput}
                  onChange={(e) => setDistrictNameInput(e.target.value)}
                  style={{ width: '100%', padding: '11px 14px', marginTop: 6, borderRadius: 8, background: '#F8FAFC', color: 'var(--text-main)', border: '1px solid #CBD5E1', outline: 'none', fontSize: '0.9rem' }}
                />
              </div>

              <div>
                <label style={{ fontSize: '0.8rem', color: 'var(--text-muted)', fontWeight: 600 }}>State</label>
                <input
                  type="text"
                  placeholder="e.g. Andhra Pradesh"
                  value={districtStateInput}
                  onChange={(e) => setDistrictStateInput(e.target.value)}
                  style={{ width: '100%', padding: '11px 14px', marginTop: 6, borderRadius: 8, background: '#F8FAFC', color: 'var(--text-main)', border: '1px solid #CBD5E1', outline: 'none', fontSize: '0.9rem' }}
                />
              </div>

              <div style={{ display: 'flex', gap: 10, marginTop: 10 }}>
                <button
                  type="button"
                  onClick={() => setShowAddDistrictModal(false)}
                  style={{ flex: 1, padding: '10px', borderRadius: 8, background: '#F1F5F9', color: 'var(--text-muted)', fontWeight: 600, cursor: 'pointer' }}
                >
                  Cancel
                </button>
                <button
                  type="submit"
                  style={{ flex: 1, padding: '10px', borderRadius: 8, background: 'var(--primary)', color: '#fff', fontWeight: 600, cursor: 'pointer', boxShadow: '0 2px 10px rgba(222, 73, 21, 0.25)' }}
                >
                  Save District
                </button>
              </div>
            </form>
          </div>
        </div>
      )}

      {/* 5. MODAL: ADD MANDAL */}
      {showAddMandalModal && (
        <div style={{
          position: 'fixed',
          top: 0,
          left: 0,
          right: 0,
          bottom: 0,
          background: 'rgba(15, 23, 42, 0.45)',
          backdropFilter: 'blur(6px)',
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'center',
          zIndex: 100
        }}>
          <div className="glass-panel" style={{ width: 420, padding: 26, background: '#FFFFFF', boxShadow: '0 20px 40px rgba(0,0,0,0.12)' }}>
            <h3 style={{ fontSize: '1.2rem', fontWeight: 700, color: 'var(--text-main)', marginBottom: 4 }}>
              Add Mandal
            </h3>
            <p style={{ fontSize: '0.82rem', color: '#DE4915', marginBottom: 16, fontWeight: 600 }}>
              In District: <strong>{targetDistrict?.name}</strong>
            </p>
            <form onSubmit={handleCreateMandal} style={{ display: 'flex', flexDirection: 'column', gap: 14 }}>
              <div>
                <label style={{ fontSize: '0.8rem', color: 'var(--text-muted)', fontWeight: 600 }}>Mandal Name</label>
                <input
                  type="text"
                  placeholder="e.g. Serilingampally, Rajendranagar, Kukatpally..."
                  autoFocus
                  required
                  value={mandalNameInput}
                  onChange={(e) => setMandalNameInput(e.target.value)}
                  style={{ width: '100%', padding: '11px 14px', marginTop: 6, borderRadius: 8, background: '#F8FAFC', color: 'var(--text-main)', border: '1px solid #CBD5E1', outline: 'none', fontSize: '0.9rem' }}
                />
              </div>

              <div style={{ display: 'flex', gap: 10, marginTop: 10 }}>
                <button
                  type="button"
                  onClick={() => setShowAddMandalModal(false)}
                  style={{ flex: 1, padding: '10px', borderRadius: 8, background: '#F1F5F9', color: 'var(--text-muted)', fontWeight: 600, cursor: 'pointer' }}
                >
                  Cancel
                </button>
                <button
                  type="submit"
                  style={{ flex: 1, padding: '10px', borderRadius: 8, background: 'var(--primary)', color: '#fff', fontWeight: 600, cursor: 'pointer', boxShadow: '0 2px 10px rgba(222, 73, 21, 0.25)' }}
                >
                  Save Mandal
                </button>
              </div>
            </form>
          </div>
        </div>
      )}

      {/* 6. MODAL: ADD VILLAGE / WARD */}
      {showAddVillageModal && (
        <div style={{
          position: 'fixed',
          top: 0,
          left: 0,
          right: 0,
          bottom: 0,
          background: 'rgba(15, 23, 42, 0.45)',
          backdropFilter: 'blur(6px)',
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'center',
          zIndex: 100
        }}>
          <div className="glass-panel" style={{ width: 420, padding: 26, background: '#FFFFFF', boxShadow: '0 20px 40px rgba(0,0,0,0.12)' }}>
            <h3 style={{ fontSize: '1.2rem', fontWeight: 700, color: 'var(--text-main)', marginBottom: 4 }}>
              Add Village / Ward
            </h3>
            <p style={{ fontSize: '0.82rem', color: '#059669', marginBottom: 16, fontWeight: 600 }}>
              Under: <strong>{targetDistrict?.name}</strong> ➔ <strong>{targetMandal?.name}</strong>
            </p>
            <form onSubmit={handleCreateVillage} style={{ display: 'flex', flexDirection: 'column', gap: 14 }}>
              <div>
                <label style={{ fontSize: '0.8rem', color: 'var(--text-muted)', fontWeight: 600 }}>Village / Ward / Area Name</label>
                <input
                  type="text"
                  placeholder="e.g. Madhapur, Gachibowli, Kondapur..."
                  autoFocus
                  required
                  value={villageNameInput}
                  onChange={(e) => setVillageNameInput(e.target.value)}
                  style={{ width: '100%', padding: '11px 14px', marginTop: 6, borderRadius: 8, background: '#F8FAFC', color: 'var(--text-main)', border: '1px solid #CBD5E1', outline: 'none', fontSize: '0.9rem' }}
                />
              </div>

              <div>
                <label style={{ fontSize: '0.8rem', color: 'var(--text-muted)', fontWeight: 600 }}>Pincode (Optional)</label>
                <input
                  type="text"
                  placeholder="e.g. 500081"
                  value={villagePincodeInput}
                  onChange={(e) => setVillagePincodeInput(e.target.value)}
                  style={{ width: '100%', padding: '11px 14px', marginTop: 6, borderRadius: 8, background: '#F8FAFC', color: 'var(--text-main)', border: '1px solid #CBD5E1', outline: 'none', fontSize: '0.9rem' }}
                />
              </div>

              <div style={{ display: 'flex', gap: 10, marginTop: 10 }}>
                <button
                  type="button"
                  onClick={() => setShowAddVillageModal(false)}
                  style={{ flex: 1, padding: '10px', borderRadius: 8, background: '#F1F5F9', color: 'var(--text-muted)', fontWeight: 600, cursor: 'pointer' }}
                >
                  Cancel
                </button>
                <button
                  type="submit"
                  style={{ flex: 1, padding: '10px', borderRadius: 8, background: '#059669', color: '#fff', fontWeight: 600, cursor: 'pointer', boxShadow: '0 2px 10px rgba(5, 150, 105, 0.25)' }}
                >
                  Save Village
                </button>
              </div>
            </form>
          </div>
        </div>
      )}

      {/* 7. MODAL: ADD CUSTOMER */}
      {showAddCustomerModal && (
        <div style={{
          position: 'fixed',
          top: 0,
          left: 0,
          right: 0,
          bottom: 0,
          background: 'rgba(15, 23, 42, 0.45)',
          backdropFilter: 'blur(6px)',
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'center',
          zIndex: 100
        }}>
          <div className="glass-panel" style={{ width: 440, padding: 26, background: '#FFFFFF', boxShadow: '0 20px 40px rgba(0,0,0,0.12)' }}>
            <h3 style={{ fontSize: '1.2rem', fontWeight: 700, color: 'var(--text-main)', marginBottom: 4 }}>
              Register Customer
            </h3>
            <p style={{ fontSize: '0.82rem', color: 'var(--text-muted)', marginBottom: 16 }}>
              Onboard a new customer profile for the Loki Customer App
            </p>
            <form onSubmit={handleCreateCustomer} style={{ display: 'flex', flexDirection: 'column', gap: 12 }}>
              <div>
                <label style={{ fontSize: '0.8rem', color: 'var(--text-muted)', fontWeight: 600 }}>Full Name</label>
                <input
                  type="text"
                  placeholder="e.g. Ramesh Kumar"
                  autoFocus
                  required
                  value={custNameInput}
                  onChange={(e) => setCustNameInput(e.target.value)}
                  style={{ width: '100%', padding: '10px 14px', marginTop: 4, borderRadius: 8, background: '#F8FAFC', color: 'var(--text-main)', border: '1px solid #CBD5E1', outline: 'none', fontSize: '0.88rem' }}
                />
              </div>

              <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 10 }}>
                <div>
                  <label style={{ fontSize: '0.8rem', color: 'var(--text-muted)', fontWeight: 600 }}>Phone Number</label>
                  <input
                    type="text"
                    placeholder="e.g. 9876543210"
                    required
                    value={custPhoneInput}
                    onChange={(e) => setCustPhoneInput(e.target.value)}
                    style={{ width: '100%', padding: '10px 14px', marginTop: 4, borderRadius: 8, background: '#F8FAFC', color: 'var(--text-main)', border: '1px solid #CBD5E1', outline: 'none', fontSize: '0.88rem' }}
                  />
                </div>
                <div>
                  <label style={{ fontSize: '0.8rem', color: 'var(--text-muted)', fontWeight: 600 }}>Email Address</label>
                  <input
                    type="email"
                    placeholder="e.g. ramesh@gmail.com"
                    value={custEmailInput}
                    onChange={(e) => setCustEmailInput(e.target.value)}
                    style={{ width: '100%', padding: '10px 14px', marginTop: 4, borderRadius: 8, background: '#F8FAFC', color: 'var(--text-main)', border: '1px solid #CBD5E1', outline: 'none', fontSize: '0.88rem' }}
                  />
                </div>
              </div>

              <div>
                <label style={{ fontSize: '0.8rem', color: 'var(--text-muted)', fontWeight: 600 }}>Street / Flat / Colony Address</label>
                <input
                  type="text"
                  placeholder="e.g. Flat 302, Green Meadows"
                  value={custAddressInput}
                  onChange={(e) => setCustAddressInput(e.target.value)}
                  style={{ width: '100%', padding: '10px 14px', marginTop: 4, borderRadius: 8, background: '#F8FAFC', color: 'var(--text-main)', border: '1px solid #CBD5E1', outline: 'none', fontSize: '0.88rem' }}
                />
              </div>

              <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr 1fr', gap: 8 }}>
                <div>
                  <label style={{ fontSize: '0.75rem', color: 'var(--text-muted)', fontWeight: 600 }}>District</label>
                  <input
                    type="text"
                    placeholder="Hyderabad"
                    value={custDistrictInput}
                    onChange={(e) => setCustDistrictInput(e.target.value)}
                    style={{ width: '100%', padding: '9px 10px', marginTop: 4, borderRadius: 8, background: '#F8FAFC', color: 'var(--text-main)', border: '1px solid #CBD5E1', outline: 'none', fontSize: '0.82rem' }}
                  />
                </div>
                <div>
                  <label style={{ fontSize: '0.75rem', color: 'var(--text-muted)', fontWeight: 600 }}>Mandal</label>
                  <input
                    type="text"
                    placeholder="Serilingampally"
                    value={custMandalInput}
                    onChange={(e) => setCustMandalInput(e.target.value)}
                    style={{ width: '100%', padding: '9px 10px', marginTop: 4, borderRadius: 8, background: '#F8FAFC', color: 'var(--text-main)', border: '1px solid #CBD5E1', outline: 'none', fontSize: '0.82rem' }}
                  />
                </div>
                <div>
                  <label style={{ fontSize: '0.75rem', color: 'var(--text-muted)', fontWeight: 600 }}>Village/Ward</label>
                  <input
                    type="text"
                    placeholder="Madhapur"
                    value={custVillageInput}
                    onChange={(e) => setCustVillageInput(e.target.value)}
                    style={{ width: '100%', padding: '9px 10px', marginTop: 4, borderRadius: 8, background: '#F8FAFC', color: 'var(--text-main)', border: '1px solid #CBD5E1', outline: 'none', fontSize: '0.82rem' }}
                  />
                </div>
              </div>

              <div style={{ display: 'flex', gap: 10, marginTop: 12 }}>
                <button
                  type="button"
                  onClick={() => setShowAddCustomerModal(false)}
                  style={{ flex: 1, padding: '10px', borderRadius: 8, background: '#F1F5F9', color: 'var(--text-muted)', fontWeight: 600, cursor: 'pointer' }}
                >
                  Cancel
                </button>
                <button
                  type="submit"
                  style={{ flex: 1, padding: '10px', borderRadius: 8, background: 'var(--primary)', color: '#fff', fontWeight: 600, cursor: 'pointer', boxShadow: '0 2px 10px rgba(222, 73, 21, 0.25)' }}
                >
                  Register Customer
                </button>
              </div>
            </form>
          </div>
        </div>
      )}

      {/* 8. MODAL: ADD SERVICE PARTNER */}
      {showAddPartnerModal && (
        <div style={{
          position: 'fixed',
          top: 0,
          left: 0,
          right: 0,
          bottom: 0,
          background: 'rgba(15, 23, 42, 0.45)',
          backdropFilter: 'blur(6px)',
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'center',
          zIndex: 100
        }}>
          <div className="glass-panel" style={{ width: 460, padding: 26, background: '#FFFFFF', boxShadow: '0 20px 40px rgba(0,0,0,0.12)' }}>
            <h3 style={{ fontSize: '1.2rem', fontWeight: 700, color: 'var(--text-main)', marginBottom: 4 }}>
              Onboard Service Partner
            </h3>
            <p style={{ fontSize: '0.82rem', color: 'var(--text-muted)', marginBottom: 16 }}>
              Register a service professional with Partner App credentials and KYC
            </p>
            <form onSubmit={handleCreatePartner} style={{ display: 'flex', flexDirection: 'column', gap: 12 }}>
              <div>
                <label style={{ fontSize: '0.8rem', color: 'var(--text-muted)', fontWeight: 600 }}>Partner Full Name</label>
                <input
                  type="text"
                  placeholder="e.g. Shiva Kumar"
                  autoFocus
                  required
                  value={partnerNameInput}
                  onChange={(e) => setPartnerNameInput(e.target.value)}
                  style={{ width: '100%', padding: '10px 14px', marginTop: 4, borderRadius: 8, background: '#F8FAFC', color: 'var(--text-main)', border: '1px solid #CBD5E1', outline: 'none', fontSize: '0.88rem' }}
                />
              </div>

              <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 10 }}>
                <div>
                  <label style={{ fontSize: '0.8rem', color: 'var(--text-muted)', fontWeight: 600 }}>Phone Number</label>
                  <input
                    type="text"
                    placeholder="e.g. 9848012345"
                    required
                    value={partnerPhoneInput}
                    onChange={(e) => setPartnerPhoneInput(e.target.value)}
                    style={{ width: '100%', padding: '10px 14px', marginTop: 4, borderRadius: 8, background: '#F8FAFC', color: 'var(--text-main)', border: '1px solid #CBD5E1', outline: 'none', fontSize: '0.88rem' }}
                  />
                </div>
                <div>
                  <label style={{ fontSize: '0.8rem', color: 'var(--text-muted)', fontWeight: 600 }}>Email Address</label>
                  <input
                    type="email"
                    placeholder="e.g. shiva@partner.loki"
                    value={partnerEmailInput}
                    onChange={(e) => setPartnerEmailInput(e.target.value)}
                    style={{ width: '100%', padding: '10px 14px', marginTop: 4, borderRadius: 8, background: '#F8FAFC', color: 'var(--text-main)', border: '1px solid #CBD5E1', outline: 'none', fontSize: '0.88rem' }}
                  />
                </div>
              </div>

              <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 10 }}>
                <div>
                  <label style={{ fontSize: '0.8rem', color: 'var(--text-muted)', fontWeight: 600 }}>Trade / Category</label>
                  <select
                    value={partnerCatInput}
                    onChange={(e) => setPartnerCatInput(e.target.value)}
                    style={{ width: '100%', padding: '10px 12px', marginTop: 4, borderRadius: 8, background: '#F8FAFC', color: 'var(--text-main)', border: '1px solid #CBD5E1', outline: 'none', fontSize: '0.88rem' }}
                  >
                    <option value="cat_plumbing">Plumbing Services</option>
                    <option value="cat_electrical">Electrical & Wiring</option>
                    <option value="cat_cleaning">Home Deep Cleaning</option>
                    <option value="cat_appliances">AC & Appliance Repair</option>
                    <option value="cat_mechanic">Bike & Car Mechanic</option>
                    <option value="cat_delivery">Hyperlocal Delivery</option>
                    <option value="cat_shops">Local Retail Merchant</option>
                  </select>
                </div>
                <div>
                  <label style={{ fontSize: '0.8rem', color: 'var(--text-muted)', fontWeight: 600 }}>Service Skill Title</label>
                  <input
                    type="text"
                    placeholder="e.g. Master Pipe Technician"
                    value={partnerServiceNameInput}
                    onChange={(e) => setPartnerServiceNameInput(e.target.value)}
                    style={{ width: '100%', padding: '10px 14px', marginTop: 4, borderRadius: 8, background: '#F8FAFC', color: 'var(--text-main)', border: '1px solid #CBD5E1', outline: 'none', fontSize: '0.88rem' }}
                  />
                </div>
              </div>

              <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 10 }}>
                <div>
                  <label style={{ fontSize: '0.8rem', color: 'var(--text-muted)', fontWeight: 600 }}>Aadhaar Number (KYC)</label>
                  <input
                    type="text"
                    placeholder="e.g. 8492-4819-3019"
                    value={partnerAadhaarInput}
                    onChange={(e) => setPartnerAadhaarInput(e.target.value)}
                    style={{ width: '100%', padding: '10px 14px', marginTop: 4, borderRadius: 8, background: '#F8FAFC', color: 'var(--text-main)', border: '1px solid #CBD5E1', outline: 'none', fontSize: '0.88rem' }}
                  />
                </div>
                <div>
                  <label style={{ fontSize: '0.8rem', color: 'var(--text-muted)', fontWeight: 600 }}>Vehicle / Reg No.</label>
                  <input
                    type="text"
                    placeholder="e.g. TS09-EA-4912"
                    value={partnerVehicleInput}
                    onChange={(e) => setPartnerVehicleInput(e.target.value)}
                    style={{ width: '100%', padding: '10px 14px', marginTop: 4, borderRadius: 8, background: '#F8FAFC', color: 'var(--text-main)', border: '1px solid #CBD5E1', outline: 'none', fontSize: '0.88rem' }}
                  />
                </div>
              </div>

              <div style={{ display: 'flex', gap: 10, marginTop: 12 }}>
                <button
                  type="button"
                  onClick={() => setShowAddPartnerModal(false)}
                  style={{ flex: 1, padding: '10px', borderRadius: 8, background: '#F1F5F9', color: 'var(--text-muted)', fontWeight: 600, cursor: 'pointer' }}
                >
                  Cancel
                </button>
                <button
                  type="submit"
                  style={{ flex: 1, padding: '10px', borderRadius: 8, background: 'var(--primary)', color: '#fff', fontWeight: 600, cursor: 'pointer', boxShadow: '0 2px 10px rgba(222, 73, 21, 0.25)' }}
                >
                  Onboard Partner
                </button>
              </div>
            </form>
          </div>
        </div>
      )}

      {/* 5. MODAL: CREATE / EDIT ADVERTISEMENT & PROMOTION */}
      {showPromoModal && (
        <div style={{
          position: 'fixed',
          top: 0,
          left: 0,
          right: 0,
          bottom: 0,
          background: 'rgba(15, 23, 42, 0.55)',
          backdropFilter: 'blur(6px)',
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'center',
          zIndex: 110,
          padding: 16
        }}>
          <div className="glass-panel" style={{
            width: '100%',
            maxWidth: 580,
            maxHeight: '92vh',
            overflowY: 'auto',
            padding: 28,
            background: '#FFFFFF',
            borderRadius: 16,
            boxShadow: '0 25px 50px rgba(0,0,0,0.18)'
          }}>
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 16 }}>
              <div>
                <h3 style={{ fontSize: '1.2rem', fontWeight: 800, color: 'var(--text-main)', margin: 0 }}>
                  {editingPromo ? '✏️ Edit Advertisement / Promotion' : '📢 Create New Advertisement / Promotion'}
                </h3>
                <p style={{ fontSize: '0.78rem', color: 'var(--text-muted)', margin: '4px 0 0' }}>
                  Live banner synchronization with Loki Customer App
                </p>
              </div>
              <button
                type="button"
                onClick={() => setShowPromoModal(false)}
                style={{
                  background: '#F1F5F9',
                  border: 'none',
                  borderRadius: 20,
                  width: 32,
                  height: 32,
                  display: 'flex',
                  alignItems: 'center',
                  justifyContent: 'center',
                  cursor: 'pointer',
                  color: '#64748B'
                }}
              >
                ✕
              </button>
            </div>

            <form onSubmit={handleSavePromo} style={{ display: 'flex', flexDirection: 'column', gap: 14 }}>
              {/* Ad Placement Selector */}
              <div>
                <label style={{ fontSize: '0.8rem', color: 'var(--text-muted)', fontWeight: 600 }}>Ad Placement / Format</label>
                <select
                  value={promoType}
                  onChange={(e) => setPromoType(e.target.value)}
                  style={{
                    width: '100%',
                    padding: '10px 14px',
                    marginTop: 4,
                    borderRadius: 8,
                    background: '#FFF4EF',
                    color: '#DE4915',
                    border: '1px solid #FFD3C2',
                    outline: 'none',
                    fontSize: '0.88rem',
                    fontWeight: 700
                  }}
                >
                  <option value="spotlight">🌟 Local Spotlight Billboard (Single Big Card Auto-Changing)</option>
                  <option value="deal">🏷️ Exclusive Deals & Offers (Sponsored Ads Carousel)</option>
                  <option value="popup">🛍️ Post-Login Grand Opening Popup Screen (With Close Button)</option>
                  <option value="hero">🚀 Top Hero Carousel Banner (Home Top)</option>
                </select>
              </div>

              {/* Title & Tag */}
              <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 12 }}>
                <div>
                  <label style={{ fontSize: '0.8rem', color: 'var(--text-muted)', fontWeight: 600 }}>Store / Business / Title *</label>
                  <input
                    type="text"
                    required
                    placeholder="e.g. Kalanikethan Silks & Fashion Mall"
                    value={promoTitle}
                    onChange={(e) => setPromoTitle(e.target.value)}
                    style={{ width: '100%', padding: '10px 14px', marginTop: 4, borderRadius: 8, background: '#F8FAFC', color: 'var(--text-main)', border: '1px solid #CBD5E1', outline: 'none', fontSize: '0.88rem' }}
                  />
                </div>
                <div>
                  <label style={{ fontSize: '0.8rem', color: 'var(--text-muted)', fontWeight: 600 }}>Event Badge / Tag</label>
                  <input
                    type="text"
                    placeholder="e.g. 🌟 GRAND SHOWROOM OPENING"
                    value={promoTag}
                    onChange={(e) => setPromoTag(e.target.value)}
                    style={{ width: '100%', padding: '10px 14px', marginTop: 4, borderRadius: 8, background: '#F8FAFC', color: 'var(--text-main)', border: '1px solid #CBD5E1', outline: 'none', fontSize: '0.88rem' }}
                  />
                </div>
              </div>

              {/* Offer & Voucher Code */}
              <div style={{ display: 'grid', gridTemplateColumns: '1.2fr 1fr', gap: 12 }}>
                <div>
                  <label style={{ fontSize: '0.8rem', color: 'var(--text-muted)', fontWeight: 600 }}>Special Offer Headline</label>
                  <input
                    type="text"
                    placeholder="e.g. FLAT 50% OFF + Free Gold Coin"
                    value={promoOffer}
                    onChange={(e) => setPromoOffer(e.target.value)}
                    style={{ width: '100%', padding: '10px 14px', marginTop: 4, borderRadius: 8, background: '#F8FAFC', color: 'var(--text-main)', border: '1px solid #CBD5E1', outline: 'none', fontSize: '0.88rem' }}
                  />
                </div>
                <div>
                  <label style={{ fontSize: '0.8rem', color: 'var(--text-muted)', fontWeight: 600 }}>Promo Voucher Code</label>
                  <input
                    type="text"
                    placeholder="e.g. LOKIFASHION50"
                    value={promoCode}
                    onChange={(e) => setPromoCode(e.target.value)}
                    style={{ width: '100%', padding: '10px 14px', marginTop: 4, borderRadius: 8, background: '#F8FAFC', color: 'var(--text-main)', border: '1px solid #CBD5E1', outline: 'none', fontSize: '0.88rem', textTransform: 'uppercase' }}
                  />
                </div>
              </div>

              {/* Subtitle / Description */}
              <div>
                <label style={{ fontSize: '0.8rem', color: 'var(--text-muted)', fontWeight: 600 }}>Description / Promotion Details</label>
                <textarea
                  rows={2}
                  placeholder="e.g. Exclusive festive designer collections, wedding wear and free ₹500 voucher on billing above ₹1,999."
                  value={promoDescription}
                  onChange={(e) => setPromoDescription(e.target.value)}
                  style={{ width: '100%', padding: '10px 14px', marginTop: 4, borderRadius: 8, background: '#F8FAFC', color: 'var(--text-main)', border: '1px solid #CBD5E1', outline: 'none', fontSize: '0.88rem', resize: 'vertical' }}
                />
              </div>

              {/* Location & CTA */}
              <div style={{ display: 'grid', gridTemplateColumns: '1.3fr 1fr', gap: 12 }}>
                <div>
                  <label style={{ fontSize: '0.8rem', color: 'var(--text-muted)', fontWeight: 600 }}>Store Location / Locality</label>
                  <input
                    type="text"
                    placeholder="e.g. Main Road, Madhapur (Opp. Metro Pillar 118)"
                    value={promoLocation}
                    onChange={(e) => setPromoLocation(e.target.value)}
                    style={{ width: '100%', padding: '10px 14px', marginTop: 4, borderRadius: 8, background: '#F8FAFC', color: 'var(--text-main)', border: '1px solid #CBD5E1', outline: 'none', fontSize: '0.88rem' }}
                  />
                </div>
                <div>
                  <label style={{ fontSize: '0.8rem', color: 'var(--text-muted)', fontWeight: 600 }}>CTA Button Text</label>
                  <input
                    type="text"
                    placeholder="e.g. Claim ₹500 Voucher & Visit"
                    value={promoCta}
                    onChange={(e) => setPromoCta(e.target.value)}
                    style={{ width: '100%', padding: '10px 14px', marginTop: 4, borderRadius: 8, background: '#F8FAFC', color: 'var(--text-main)', border: '1px solid #CBD5E1', outline: 'none', fontSize: '0.88rem' }}
                  />
                </div>
              </div>

              {/* Image URL with live preview */}
              <div>
                <label style={{ fontSize: '0.8rem', color: 'var(--text-muted)', fontWeight: 600 }}>Banner Image URL</label>
                <input
                  type="url"
                  placeholder="https://images.unsplash.com/photo-..."
                  value={promoImageUrl}
                  onChange={(e) => setPromoImageUrl(e.target.value)}
                  style={{ width: '100%', padding: '10px 14px', marginTop: 4, borderRadius: 8, background: '#F8FAFC', color: 'var(--text-main)', border: '1px solid #CBD5E1', outline: 'none', fontSize: '0.85rem' }}
                />
                {promoImageUrl && (
                  <div style={{ marginTop: 8, borderRadius: 8, overflow: 'hidden', height: 110, position: 'relative', border: '1px solid #E2E8F0' }}>
                    <img
                      src={promoImageUrl}
                      alt="Banner Preview"
                      style={{ width: '100%', height: '100%', objectFit: 'cover' }}
                      onError={(e) => { e.target.style.display = 'none'; }}
                    />
                    <span style={{ position: 'absolute', bottom: 6, right: 8, background: 'rgba(0,0,0,0.6)', color: '#fff', fontSize: '0.68rem', padding: '2px 6px', borderRadius: 4 }}>
                      Live Preview
                    </span>
                  </div>
                )}
              </div>

              {/* Status & Priority */}
              <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', padding: '10px 14px', background: '#F8FAFC', borderRadius: 8, border: '1px solid #E2E8F0' }}>
                <label style={{ display: 'flex', alignItems: 'center', gap: 10, cursor: 'pointer', fontSize: '0.85rem', fontWeight: 600, color: '#334155' }}>
                  <input
                    type="checkbox"
                    checked={promoActive}
                    onChange={(e) => setPromoActive(e.target.checked)}
                    style={{ width: 17, height: 17, accentColor: '#DE4915' }}
                  />
                  <span>Active & Live on Customer App</span>
                </label>

                <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
                  <label style={{ fontSize: '0.78rem', color: '#64748B', fontWeight: 600 }}>Priority:</label>
                  <input
                    type="number"
                    min="1"
                    max="99"
                    value={promoPriority}
                    onChange={(e) => setPromoPriority(e.target.value)}
                    style={{ width: 55, padding: '4px 8px', borderRadius: 6, border: '1px solid #CBD5E1', textAlign: 'center', fontWeight: 700 }}
                  />
                </div>
              </div>

              {/* Submit / Cancel Buttons */}
              <div style={{ display: 'flex', gap: 10, marginTop: 10 }}>
                <button
                  type="button"
                  onClick={() => setShowPromoModal(false)}
                  style={{ flex: 1, padding: '11px', borderRadius: 8, background: '#F1F5F9', color: 'var(--text-muted)', fontWeight: 600, cursor: 'pointer', border: 'none' }}
                >
                  Cancel
                </button>
                <button
                  type="submit"
                  style={{ flex: 1.5, padding: '11px', borderRadius: 8, background: 'linear-gradient(135deg, #DE4915 0%, #B8350B 100%)', color: '#fff', fontWeight: 700, cursor: 'pointer', border: 'none', boxShadow: '0 4px 14px rgba(222, 73, 21, 0.3)' }}
                >
                  {editingPromo ? 'Update Advertisement' : 'Publish Ad to Customer App'}
                </button>
              </div>
            </form>
          </div>
        </div>
      )}

      {/* 9. MODAL: SUB-CATEGORY SUBSCRIPTION PRICING */}
      {subPricingModal && (
        <div style={{
          position: 'fixed',
          top: 0,
          left: 0,
          right: 0,
          bottom: 0,
          background: 'rgba(15, 23, 42, 0.65)',
          backdropFilter: 'blur(4px)',
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'center',
          zIndex: 1100,
          padding: 20
        }}>
          <div style={{
            background: '#fff',
            borderRadius: 16,
            width: '100%',
            maxWidth: 480,
            padding: 24,
            boxShadow: '0 20px 25px -5px rgba(0, 0, 0, 0.1), 0 10px 10px -5px rgba(0, 0, 0, 0.04)',
            border: '1px solid #E2E8F0'
          }}>
            <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: 14 }}>
              <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
                <span style={{ fontSize: '1.4rem' }}>💳</span>
                <div>
                  <h3 style={{ margin: 0, fontSize: '1.15rem', fontWeight: 800, color: '#1E293B' }}>
                    Set Subscription Rates
                  </h3>
                  <p style={{ margin: 0, fontSize: '0.8rem', color: '#D97706', fontWeight: 600 }}>
                    Sub-Category: {subPricingModal.sub?.name}
                  </p>
                </div>
              </div>
              <button
                onClick={() => setSubPricingModal(null)}
                style={{ background: '#F1F5F9', border: 'none', borderRadius: '50%', width: 32, height: 32, cursor: 'pointer', fontSize: '1rem', color: '#64748B' }}
              >
                ✕
              </button>
            </div>

            <p style={{ fontSize: '0.82rem', color: '#64748B', marginBottom: 18, lineHeight: 1.4 }}>
              Set customized subscription rates for service partners registered under <strong>{subPricingModal.sub?.name}</strong>. Partners retain 100% customer earnings (0% commission).
            </p>

            <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 14, marginBottom: 18 }}>
              {/* 1 Month */}
              <div style={{ background: '#F8FAFC', padding: 12, borderRadius: 10, border: '1px solid #E2E8F0' }}>
                <label style={{ display: 'block', fontSize: '0.75rem', fontWeight: 700, color: '#475569', marginBottom: 6 }}>
                  📅 1 Month Plan (₹)
                </label>
                <div style={{ position: 'relative' }}>
                  <span style={{ position: 'absolute', left: 10, top: '50%', transform: 'translateY(-50%)', fontWeight: 700, color: '#94A3B8' }}>₹</span>
                  <input
                    type="number"
                    min="1"
                    value={sub1mInput}
                    onChange={(e) => setSub1mInput(e.target.value)}
                    style={{ width: '100%', padding: '8px 10px 8px 24px', borderRadius: 8, border: '1px solid #CBD5E1', fontSize: '0.95rem', fontWeight: 700, color: '#1E293B' }}
                  />
                </div>
              </div>

              {/* 3 Months */}
              <div style={{ background: '#EFF6FF', padding: 12, borderRadius: 10, border: '1px solid #BFDBFE' }}>
                <label style={{ display: 'block', fontSize: '0.75rem', fontWeight: 700, color: '#1D4ED8', marginBottom: 6 }}>
                  📅 3 Months Plan (₹)
                </label>
                <div style={{ position: 'relative' }}>
                  <span style={{ position: 'absolute', left: 10, top: '50%', transform: 'translateY(-50%)', fontWeight: 700, color: '#93C5FD' }}>₹</span>
                  <input
                    type="number"
                    min="1"
                    value={sub3mInput}
                    onChange={(e) => setSub3mInput(e.target.value)}
                    style={{ width: '100%', padding: '8px 10px 8px 24px', borderRadius: 8, border: '1px solid #93C5FD', fontSize: '0.95rem', fontWeight: 700, color: '#1E293B' }}
                  />
                </div>
              </div>

              {/* 6 Months */}
              <div style={{ background: '#F8FAFC', padding: 12, borderRadius: 10, border: '1px solid #E2E8F0' }}>
                <label style={{ display: 'block', fontSize: '0.75rem', fontWeight: 700, color: '#475569', marginBottom: 6 }}>
                  📅 6 Months Plan (₹)
                </label>
                <div style={{ position: 'relative' }}>
                  <span style={{ position: 'absolute', left: 10, top: '50%', transform: 'translateY(-50%)', fontWeight: 700, color: '#94A3B8' }}>₹</span>
                  <input
                    type="number"
                    min="1"
                    value={sub6mInput}
                    onChange={(e) => setSub6mInput(e.target.value)}
                    style={{ width: '100%', padding: '8px 10px 8px 24px', borderRadius: 8, border: '1px solid #CBD5E1', fontSize: '0.95rem', fontWeight: 700, color: '#1E293B' }}
                  />
                </div>
              </div>

              {/* 1 Year */}
              <div style={{ background: '#FFFBEB', padding: 12, borderRadius: 10, border: '1px solid #FCD34D' }}>
                <label style={{ display: 'block', fontSize: '0.75rem', fontWeight: 700, color: '#B45309', marginBottom: 6 }}>
                  🏆 1 Year Annual Plan (₹)
                </label>
                <div style={{ position: 'relative' }}>
                  <span style={{ position: 'absolute', left: 10, top: '50%', transform: 'translateY(-50%)', fontWeight: 700, color: '#FBBF24' }}>₹</span>
                  <input
                    type="number"
                    min="1"
                    value={sub1yInput}
                    onChange={(e) => setSub1yInput(e.target.value)}
                    style={{ width: '100%', padding: '8px 10px 8px 24px', borderRadius: 8, border: '1px solid #FCD34D', fontSize: '0.95rem', fontWeight: 700, color: '#1E293B' }}
                  />
                </div>
              </div>
            </div>

            <div style={{ background: '#FEF3C7', padding: '10px 14px', borderRadius: 10, marginBottom: 20, display: 'flex', alignItems: 'center', gap: 10 }}>
              <span style={{ fontSize: '1.1rem' }}>💡</span>
              <p style={{ margin: 0, fontSize: '0.78rem', color: '#92400E', lineHeight: 1.4 }}>
                Changes will take effect immediately. Existing active subscriptions will remain valid till their renewal date.
              </p>
            </div>

            <div style={{ display: 'flex', gap: 10 }}>
              <button
                type="button"
                onClick={() => setSubPricingModal(null)}
                style={{ flex: 1, padding: '11px', borderRadius: 8, background: '#F1F5F9', color: '#475569', fontWeight: 600, cursor: 'pointer', border: 'none' }}
              >
                Cancel
              </button>
              <button
                type="button"
                onClick={handleSaveSubPricing}
                style={{ flex: 1.5, padding: '11px', borderRadius: 8, background: 'linear-gradient(135deg, #DE4915 0%, #B8350B 100%)', color: '#fff', fontWeight: 700, cursor: 'pointer', border: 'none', boxShadow: '0 4px 14px rgba(222, 73, 21, 0.3)' }}
              >
                Save Subscription Rates
              </button>
            </div>
          </div>
        </div>
      )}

      {/* 10. MODAL: RECORD PARTNER SUBSCRIPTION PAYMENT */}
      {paySubModal && (
        <div style={{
          position: 'fixed',
          top: 0,
          left: 0,
          right: 0,
          bottom: 0,
          background: 'rgba(15, 23, 42, 0.65)',
          backdropFilter: 'blur(4px)',
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'center',
          zIndex: 1100,
          padding: 20
        }}>
          <div style={{
            background: '#fff',
            borderRadius: 16,
            width: '100%',
            maxWidth: 500,
            padding: 24,
            boxShadow: '0 20px 25px -5px rgba(0, 0, 0, 0.1)',
            border: '1px solid #E2E8F0'
          }}>
            <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: 14 }}>
              <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
                <span style={{ fontSize: '1.4rem' }}>💳</span>
                <div>
                  <h3 style={{ margin: 0, fontSize: '1.15rem', fontWeight: 800, color: '#1E293B' }}>
                    Record Subscription Payment
                  </h3>
                  <p style={{ margin: 0, fontSize: '0.8rem', color: '#059669', fontWeight: 600 }}>
                    Partner: {paySubModal.partner?.name} ({paySubModal.partner?.partnerCode || paySubModal.partner?.id})
                  </p>
                </div>
              </div>
              <button
                onClick={() => setPaySubModal(null)}
                style={{ background: '#F1F5F9', border: 'none', borderRadius: '50%', width: 32, height: 32, cursor: 'pointer', fontSize: '1rem', color: '#64748B' }}
              >
                ✕
              </button>
            </div>

            <div style={{ background: '#F8FAFC', padding: '10px 14px', borderRadius: 10, border: '1px solid #E2E8F0', marginBottom: 16 }}>
              <p style={{ margin: 0, fontSize: '0.78rem', color: '#64748B' }}>
                Assigned Category: <strong>{paySubModal.cat?.name || 'General'}</strong>
                {paySubModal.sub ? <> ↳ <strong>{paySubModal.sub.name}</strong></> : null}
              </p>
            </div>

            {/* Duration Selector */}
            <label style={{ display: 'block', fontSize: '0.8rem', fontWeight: 700, color: '#334155', marginBottom: 8 }}>
              Select Plan Duration:
            </label>
            <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 10, marginBottom: 16 }}>
              {[
                { id: '1_month', label: '1 Month', rate: paySubModal.plans?.['1_month'] || 199 },
                { id: '3_months', label: '3 Months', rate: paySubModal.plans?.['3_months'] || 499 },
                { id: '6_months', label: '6 Months', rate: paySubModal.plans?.['6_months'] || 899 },
                { id: '1_year', label: '1 Year (Annual)', rate: paySubModal.plans?.['1_year'] || 1499 },
              ].map(plan => {
                const isSelected = payPlanDuration === plan.id;
                return (
                  <div
                    key={plan.id}
                    onClick={() => {
                      setPayPlanDuration(plan.id);
                      setPayCustomAmount(plan.rate);
                    }}
                    style={{
                      padding: '12px 14px',
                      borderRadius: 10,
                      border: isSelected ? '2px solid #DE4915' : '1px solid #E2E8F0',
                      background: isSelected ? '#FFF7ED' : '#FAFAFA',
                      cursor: 'pointer',
                      display: 'flex',
                      justifyContent: 'space-between',
                      alignItems: 'center'
                    }}
                  >
                    <div>
                      <div style={{ fontWeight: 700, fontSize: '0.85rem', color: isSelected ? '#C2410C' : '#334155' }}>{plan.label}</div>
                      <div style={{ fontSize: '0.75rem', color: '#64748B' }}>0% commission</div>
                    </div>
                    <div style={{ fontWeight: 800, fontSize: '1rem', color: isSelected ? '#DE4915' : '#1E293B' }}>₹{plan.rate}</div>
                  </div>
                );
              })}
            </div>

            {/* Payment Method */}
            <label style={{ display: 'block', fontSize: '0.8rem', fontWeight: 700, color: '#334155', marginBottom: 8 }}>
              Payment Received Mode:
            </label>
            <div style={{ display: 'flex', gap: 10, marginBottom: 20 }}>
              {[
                { id: 'cash', label: '💵 Cash in Hand' },
                { id: 'upi', label: '📱 Direct UPI / QR' },
                { id: 'bank', label: '🏦 Bank Transfer' },
              ].map(m => (
                <button
                  key={m.id}
                  type="button"
                  onClick={() => setPayMethod(m.id)}
                  style={{
                    flex: 1,
                    padding: '9px 6px',
                    borderRadius: 8,
                    border: payMethod === m.id ? '2px solid #059669' : '1px solid #CBD5E1',
                    background: payMethod === m.id ? '#ECFDF5' : '#fff',
                    color: payMethod === m.id ? '#065F46' : '#475569',
                    fontWeight: 700,
                    fontSize: '0.78rem',
                    cursor: 'pointer'
                  }}
                >
                  {m.label}
                </button>
              ))}
            </div>

            <div style={{ display: 'flex', gap: 10 }}>
              <button
                type="button"
                onClick={() => setPaySubModal(null)}
                style={{ flex: 1, padding: '11px', borderRadius: 8, background: '#F1F5F9', color: '#475569', fontWeight: 600, cursor: 'pointer', border: 'none' }}
              >
                Cancel
              </button>
              <button
                type="button"
                onClick={handleConfirmSubscriptionPayment}
                style={{ flex: 1.5, padding: '11px', borderRadius: 8, background: 'linear-gradient(135deg, #059669 0%, #047857 100%)', color: '#fff', fontWeight: 700, cursor: 'pointer', border: 'none', boxShadow: '0 4px 14px rgba(5, 150, 105, 0.3)' }}
              >
                ✓ Confirm & Activate Plan
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}

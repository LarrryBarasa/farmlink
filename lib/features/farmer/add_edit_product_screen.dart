import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/widgets/primary_button.dart';
import '../../models/product_model.dart';
import '../../services/product_service.dart';

class AddEditProductScreen extends StatefulWidget {
  final String farmerId;
  final Product? existingProduct;

  const AddEditProductScreen({
    super.key,
    required this.farmerId,
    this.existingProduct,
  });

  @override
  State<AddEditProductScreen> createState() => _AddEditProductScreenState();
}

class _AddEditProductScreenState extends State<AddEditProductScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController nameController;
  late final TextEditingController priceController;
  late final TextEditingController stockController;
  late final TextEditingController deliveryChargeController;

  ProductCategory _category = ProductCategory.crop;
  String _unit = 'kg';
  DeliveryMode _deliveryMode = DeliveryMode.platformDelivery;

  bool _saving = false;

  final List<String> _units = [
    'kg',
    'litre',
    'crate',
    'bunch',
    'head',
    'piece',
  ];

  @override
  void initState() {
    super.initState();

    final product = widget.existingProduct;

    nameController = TextEditingController(text: product?.name ?? '');

    priceController = TextEditingController(
      text: product != null ? product.farmerPrice.toString() : '',
    );

    stockController = TextEditingController(
      text: product != null ? product.stockQuantity.toString() : '',
    );

    deliveryChargeController = TextEditingController(
      text: product?.farmerDeliveryCharge?.toString() ?? '',
    );

    if (product != null) {
      _category = product.category;
      _unit = product.unit;
      _deliveryMode = product.deliveryMode;
    }

    priceController.addListener(_onValuesChanged);
    stockController.addListener(_onValuesChanged);
  }

  void _onValuesChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    priceController.removeListener(_onValuesChanged);
    stockController.removeListener(_onValuesChanged);

    nameController.dispose();
    priceController.dispose();
    stockController.dispose();
    deliveryChargeController.dispose();

    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _saving = true;
    });

    try {
      final farmerPrice = double.tryParse(priceController.text.trim());

      final stock = int.tryParse(stockController.text.trim());

      final deliveryText = deliveryChargeController.text.trim();

      final deliveryCharge = deliveryText.isNotEmpty
          ? double.tryParse(deliveryText)
          : null;

      if (farmerPrice == null || stock == null) {
        throw Exception('Please enter valid price and stock values.');
      }

      if (deliveryText.isNotEmpty && deliveryCharge == null) {
        throw Exception('Please enter a valid delivery charge.');
      }

      final service = ProductService();

      final nameToCheck = nameController.text.trim();

      final duplicateExists = await service.productNameExists(
        widget.farmerId,
        nameToCheck,
        excludeId: widget.existingProduct?.id,
      );

      if (duplicateExists) {
        throw Exception(
          'You already have a product named "$nameToCheck". '
          'Edit that one instead, or use a different name.',
        );
      }

      if (widget.existingProduct == null) {
        await service.addProduct(
          farmerId: widget.farmerId,
          name: nameToCheck,
          category: _category,
          farmerPrice: farmerPrice,
          unit: _unit,
          stockQuantity: stock,
          deliveryMode: _deliveryMode,
          farmerDeliveryCharge: deliveryCharge,
        );
      } else {
        await service.updateProduct(widget.existingProduct!.id, {
          'name': nameToCheck,
          'category': _category.name,
          'farmerPrice': farmerPrice,
          'unit': _unit,
          'stockQuantity': stock,
          'deliveryMode': _deliveryMode.name,
          'farmerDeliveryCharge': deliveryCharge,
        });
      }

      if (!mounted) return;

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      final message = e.toString().replaceFirst('Exception: ', '');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }

  Future<void> _delete() async {
    if (widget.existingProduct == null || _saving) {
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Product'),
          content: const Text(
            'Are you sure you want to delete this product? '
            'This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context, true);
              },
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    setState(() {
      _saving = true;
    });

    try {
      await ProductService().deleteProduct(widget.existingProduct!.id);

      if (!mounted) return;

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not delete product: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existingProduct != null;

    final price = double.tryParse(priceController.text.trim()) ?? 0;
    final stock = int.tryParse(stockController.text.trim()) ?? 0;
    final totalValue = price * stock;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Product' : 'Add Product'),
        actions: [
          if (isEditing)
            IconButton(
              onPressed: _saving ? null : _delete,
              icon: const Icon(Icons.delete_outline, color: Colors.red),
            ),
        ],
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              AppTextField(
                controller: nameController,
                label: 'Product Name',
                icon: Icons.eco,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Enter a product name';
                  }

                  return null;
                },
              ),

              const SizedBox(height: 20),

              DropdownButtonFormField<ProductCategory>(
                value: _category,
                decoration: InputDecoration(
                  labelText: 'Category',
                  filled: true,
                  fillColor: AppColors.background,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                items: ProductCategory.values.map((category) {
                  return DropdownMenuItem<ProductCategory>(
                    value: category,
                    child: Text(category.name),
                  );
                }).toList(),
                onChanged: _saving
                    ? null
                    : (value) {
                        if (value == null) return;

                        setState(() {
                          _category = value;
                        });
                      },
              ),

              const SizedBox(height: 20),

              AppTextField(
                controller: priceController,
                label: 'Your Price (KES)',
                icon: Icons.attach_money,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Enter a price';
                  }

                  final price = double.tryParse(value.trim());

                  if (price == null || price <= 0) {
                    return 'Enter a valid price';
                  }

                  return null;
                },
              ),

              const SizedBox(height: 20),

              DropdownButtonFormField<String>(
                value: _unit,
                decoration: InputDecoration(
                  labelText: 'Unit',
                  filled: true,
                  fillColor: AppColors.background,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                items: _units.map((unit) {
                  return DropdownMenuItem<String>(
                    value: unit,
                    child: Text(unit),
                  );
                }).toList(),
                onChanged: _saving
                    ? null
                    : (value) {
                        if (value == null) return;

                        setState(() {
                          _unit = value;
                        });
                      },
              ),

              const SizedBox(height: 20),

              AppTextField(
                controller: stockController,
                label: 'Stock Quantity',
                icon: Icons.inventory_2,
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Enter stock quantity';
                  }

                  final stock = int.tryParse(value.trim());

                  if (stock == null || stock < 0) {
                    return 'Enter a valid whole number';
                  }

                  return null;
                },
              ),

              const SizedBox(height: 20),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  vertical: 14,
                  horizontal: 16,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Total Value',
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        color: AppColors.dark,
                      ),
                    ),
                    Text(
                      'KES ${totalValue.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              DropdownButtonFormField<DeliveryMode>(
                value: _deliveryMode,
                decoration: InputDecoration(
                  labelText: 'Delivery',
                  filled: true,
                  fillColor: AppColors.background,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                items: const [
                  DropdownMenuItem(
                    value: DeliveryMode.platformDelivery,
                    child: Text('Farmlink delivers it'),
                  ),
                  DropdownMenuItem(
                    value: DeliveryMode.farmerSelf,
                    child: Text('I deliver it myself'),
                  ),
                  DropdownMenuItem(
                    value: DeliveryMode.both,
                    child: Text('Either option'),
                  ),
                ],
                onChanged: _saving
                    ? null
                    : (value) {
                        if (value == null) return;

                        setState(() {
                          _deliveryMode = value;
                        });
                      },
              ),

              if (_deliveryMode == DeliveryMode.farmerSelf ||
                  _deliveryMode == DeliveryMode.both) ...[
                const SizedBox(height: 20),

                AppTextField(
                  controller: deliveryChargeController,
                  label: 'Your Delivery Charge (KES)',
                  icon: Icons.local_shipping,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return null;
                    }

                    final charge = double.tryParse(value.trim());

                    if (charge == null || charge < 0) {
                      return 'Enter a valid delivery charge';
                    }

                    return null;
                  },
                ),
              ],

              const SizedBox(height: 35),

              _saving
                  ? const CircularProgressIndicator()
                  : PrimaryButton(
                      text: isEditing ? 'Save Changes' : 'Add Product',
                      onPressed: _save,
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
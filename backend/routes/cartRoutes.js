const express = require('express');
const router = express.Router();
const Cart = require('../models/Cart');

// 1. GET User Cart
router.get('/:userId', async (req, res) => {
  try {
    const { userId } = req.params;
    if (!userId) {
      return res.status(400).json({ success: false, message: 'userId is required' });
    }

    let cart = await Cart.findOne({ userId });
    if (!cart) {
      cart = await Cart.create({ userId, items: [] });
    }

    const totalCount = cart.items.reduce((sum, item) => sum + (item.quantity || 0), 0);

    return res.status(200).json({
      success: true,
      data: {
        userId: cart.userId,
        items: cart.items,
        totalCount,
      },
    });
  } catch (error) {
    console.error('Error fetching cart:', error);
    return res.status(500).json({ success: false, message: 'Failed to fetch cart', error: error.message });
  }
});

// 2. ADD Item to Cart (or increment quantity)
router.post('/add', async (req, res) => {
  try {
    const { userId, productId, quantity = 1, product = {} } = req.body;
    if (!userId || !productId) {
      return res.status(400).json({ success: false, message: 'userId and productId are required' });
    }

    let cart = await Cart.findOne({ userId });
    if (!cart) {
      cart = new Cart({ userId, items: [] });
    }

    const itemIndex = cart.items.findIndex((item) => item.productId === productId.toString());

    if (itemIndex > -1) {
      cart.items[itemIndex].quantity += Number(quantity);
      if (product && Object.keys(product).length > 0) {
        cart.items[itemIndex].product = {
          ...cart.items[itemIndex].product,
          ...product,
          id: productId,
        };
      }
    } else {
      cart.items.push({
        productId: productId.toString(),
        quantity: Math.max(1, Number(quantity)),
        product: { ...product, id: productId },
      });
    }

    await cart.save();
    const totalCount = cart.items.reduce((sum, item) => sum + (item.quantity || 0), 0);

    return res.status(200).json({
      success: true,
      message: 'Item added to cart successfully',
      data: {
        userId: cart.userId,
        items: cart.items,
        totalCount,
      },
    });
  } catch (error) {
    console.error('Error adding to cart:', error);
    return res.status(500).json({ success: false, message: 'Failed to add item to cart', error: error.message });
  }
});

// 3. UPDATE Item Quantity in Cart
router.put('/update', async (req, res) => {
  try {
    const { userId, productId, quantity, product } = req.body;
    if (!userId || !productId || quantity === undefined) {
      return res.status(400).json({ success: false, message: 'userId, productId and quantity are required' });
    }

    let cart = await Cart.findOne({ userId });
    if (!cart) {
      cart = new Cart({ userId, items: [] });
    }

    const itemIndex = cart.items.findIndex((item) => item.productId === productId.toString());
    const newQty = Number(quantity);

    if (newQty <= 0) {
      if (itemIndex > -1) {
        cart.items.splice(itemIndex, 1);
      }
    } else {
      if (itemIndex > -1) {
        cart.items[itemIndex].quantity = newQty;
        if (product && Object.keys(product).length > 0) {
          cart.items[itemIndex].product = {
            ...cart.items[itemIndex].product,
            ...product,
            id: productId,
          };
        }
      } else {
        cart.items.push({
          productId: productId.toString(),
          quantity: newQty,
          product: { ...(product || {}), id: productId },
        });
      }
    }

    await cart.save();
    const totalCount = cart.items.reduce((sum, item) => sum + (item.quantity || 0), 0);

    return res.status(200).json({
      success: true,
      message: 'Cart updated successfully',
      data: {
        userId: cart.userId,
        items: cart.items,
        totalCount,
      },
    });
  } catch (error) {
    console.error('Error updating cart:', error);
    return res.status(500).json({ success: false, message: 'Failed to update cart', error: error.message });
  }
});

// 4. REMOVE Item from Cart
router.delete('/:userId/item/:productId', async (req, res) => {
  try {
    const { userId, productId } = req.params;
    if (!userId || !productId) {
      return res.status(400).json({ success: false, message: 'userId and productId are required' });
    }

    const cart = await Cart.findOne({ userId });
    if (!cart) {
      return res.status(200).json({
        success: true,
        message: 'Cart is already empty',
        data: { userId, items: [], totalCount: 0 },
      });
    }

    cart.items = cart.items.filter((item) => item.productId !== productId.toString());
    await cart.save();

    const totalCount = cart.items.reduce((sum, item) => sum + (item.quantity || 0), 0);

    return res.status(200).json({
      success: true,
      message: 'Item removed from cart',
      data: {
        userId: cart.userId,
        items: cart.items,
        totalCount,
      },
    });
  } catch (error) {
    console.error('Error removing item from cart:', error);
    return res.status(500).json({ success: false, message: 'Failed to remove item', error: error.message });
  }
});

// 5. CLEAR Cart
router.delete('/:userId/clear', async (req, res) => {
  try {
    const { userId } = req.params;
    if (!userId) {
      return res.status(400).json({ success: false, message: 'userId is required' });
    }

    await Cart.findOneAndUpdate({ userId }, { items: [] }, { upsert: true, new: true });

    return res.status(200).json({
      success: true,
      message: 'Cart cleared successfully',
      data: { userId, items: [], totalCount: 0 },
    });
  } catch (error) {
    console.error('Error clearing cart:', error);
    return res.status(500).json({ success: false, message: 'Failed to clear cart', error: error.message });
  }
});

// 6. SYNC Full Cart (Bulk)
router.post('/:userId/sync', async (req, res) => {
  try {
    const { userId } = req.params;
    const { items = [] } = req.body;

    if (!userId) {
      return res.status(400).json({ success: false, message: 'userId is required' });
    }

    const formattedItems = items.map((it) => ({
      productId: (it.productId || it.id).toString(),
      quantity: Number(it.quantity || 1),
      product: it.product || {},
    }));

    const cart = await Cart.findOneAndUpdate(
      { userId },
      { items: formattedItems },
      { upsert: true, new: true }
    );

    const totalCount = cart.items.reduce((sum, item) => sum + (item.quantity || 0), 0);

    return res.status(200).json({
      success: true,
      message: 'Cart synced successfully',
      data: {
        userId: cart.userId,
        items: cart.items,
        totalCount,
      },
    });
  } catch (error) {
    console.error('Error syncing cart:', error);
    return res.status(500).json({ success: false, message: 'Failed to sync cart', error: error.message });
  }
});

module.exports = router;

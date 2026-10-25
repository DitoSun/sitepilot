const PRICES = { basic: 5, pro: 15, team: 40 };
module.exports = {
  priceOf: (plan) => PRICES[plan] ?? 0,
  isValid: (plan) => plan in PRICES,
};

import { ajax } from "discourse/lib/ajax";
import { popupAjaxError } from "discourse/lib/ajax-error";

export default Ember.Component.extend({
  loading: false,
  selectedDate: null,
  userPoints: 0,
  settings: null,
  availableDates: null,

  didInsertElement() {
    this._super(...arguments);
    this.set('settings', {});
    this.set('availableDates', []);
    this.send('loadUserPoints');
    this.send('loadSettings');
  },

  actions: {
    loadUserPoints() {
      ajax("/check-in/points").then((response) => {
        if (response.success) {
          this.set('userPoints', response.data.total_points);
        }
      }).catch((error) => {
        popupAjaxError(error);
      });
    },

    loadSettings() {
      ajax("/check-in/check-in-status").then((response) => {
        if (response.success) {
          this.set('settings', response.data.settings);
          this.send('generateAvailableDates');
        }
      }).catch((error) => {
        popupAjaxError(error);
      });
    },

    generateAvailableDates() {
      if (!this.get('settings.makeup_enabled')) return;

      const maxDays = this.get('settings.makeup_max_days') || 7;
      const today = new Date();
      const dates = [];

      for (let i = 1; i <= maxDays; i++) {
        const date = new Date(today);
        date.setDate(today.getDate() - i);
        dates.push({
          value: date.toISOString().split('T')[0],
          label: this.formatDate(date),
          dayOfWeek: date.toLocaleDateString('en-US', { weekday: 'short' })
        });
      }

      this.set('availableDates', dates);
    },

    selectDate(dateValue) {
      this.set('selectedDate', dateValue);
    },

    performMakeup() {
      if (!this.selectedDate || this.loading) return;

      if (!this.get('canAffordMakeup')) {
        if (this.appEvents) {
          this.appEvents.trigger("check-in:error", {
            message: I18n.t("check_in.makeup.insufficient_points")
          });
        }
        return;
      }

      this.set('loading', true);

      ajax("/check-in/makeup-check-in", {
        type: "POST",
        data: { date: this.selectedDate }
      }).then((response) => {
        if (response.success) {
          if (this.appEvents) {
            this.appEvents.trigger("check-in:makeup-success", {
              date: response.data.date,
              pointsEarned: response.data.points_earned,
              makeupCost: response.data.makeup_cost,
              netPoints: response.data.net_points
            });
          }

          // Refresh user points
          this.send('loadUserPoints');

          // Reset selection
          this.set('selectedDate', null);
        }
      }).catch((error) => {
        popupAjaxError(error);
      }).finally(() => {
        this.set('loading', false);
      });
    }
  },

  formatDate(date) {
    return date.toLocaleDateString('en-US', {
      month: 'short',
      day: 'numeric',
      year: 'numeric'
    });
  },

  canAffordMakeup: function() {
    const cost = this.get('settings.makeup_cost_points') || 0;
    return this.userPoints >= cost;
  }.property('userPoints', 'settings.makeup_cost_points'),

  makeupCost: function() {
    return this.get('settings.makeup_cost_points') || 0;
  }.property('settings.makeup_cost_points'),

  netGain: function() {
    const dailyPoints = this.get('settings.daily_points') || 0;
    return dailyPoints - this.get('makeupCost');
  }.property('settings.daily_points', 'makeupCost'),

  canPerformMakeup: function() {
    return this.selectedDate && this.get('canAffordMakeup') && !this.loading;
  }.property('selectedDate', 'canAffordMakeup', 'loading'),

  makeupEnabled: function() {
    return this.get('settings.makeup_enabled');
  }.property('settings.makeup_enabled')
});

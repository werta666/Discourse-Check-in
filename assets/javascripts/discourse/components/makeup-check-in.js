import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { action } from "@ember/object";
import { inject as service } from "@ember/service";
import { ajax } from "discourse/lib/ajax";
import { popupAjaxError } from "discourse/lib/ajax-error";
import I18n from "I18n";

export default class MakeupCheckIn extends Component {
  @service currentUser;
  @service appEvents;
  
  @tracked loading = false;
  @tracked selectedDate = null;
  @tracked userPoints = 0;
  @tracked settings = {};
  @tracked availableDates = [];

  constructor() {
    super(...arguments);
    this.loadUserPoints();
    this.loadSettings();
    this.generateAvailableDates();
  }

  @action
  async loadUserPoints() {
    try {
      const response = await ajax("/check-in/points");
      if (response.success) {
        this.userPoints = response.data.total_points;
      }
    } catch (error) {
      popupAjaxError(error);
    }
  }

  @action
  async loadSettings() {
    try {
      const response = await ajax("/check-in/check-in-status");
      if (response.success) {
        this.settings = response.data.settings;
        this.generateAvailableDates();
      }
    } catch (error) {
      popupAjaxError(error);
    }
  }

  @action
  generateAvailableDates() {
    if (!this.settings.makeup_enabled) return;
    
    const maxDays = this.settings.makeup_max_days || 7;
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
    
    this.availableDates = dates;
  }

  @action
  formatDate(date) {
    return date.toLocaleDateString('en-US', {
      month: 'short',
      day: 'numeric',
      year: 'numeric'
    });
  }

  @action
  selectDate(dateValue) {
    this.selectedDate = dateValue;
  }

  @action
  async performMakeup() {
    if (!this.selectedDate || this.loading) return;
    
    if (!this.canAffordMakeup) {
      this.appEvents.trigger("check-in:error", {
        message: I18n.t("check_in.makeup.insufficient_points")
      });
      return;
    }

    this.loading = true;
    
    try {
      const response = await ajax("/check-in/makeup-check-in", {
        type: "POST",
        data: { date: this.selectedDate }
      });

      if (response.success) {
        this.appEvents.trigger("check-in:makeup-success", {
          date: response.data.date,
          pointsEarned: response.data.points_earned,
          makeupCost: response.data.makeup_cost,
          netPoints: response.data.net_points
        });
        
        // Refresh user points
        this.loadUserPoints();
        
        // Reset selection
        this.selectedDate = null;
      }
    } catch (error) {
      popupAjaxError(error);
    } finally {
      this.loading = false;
    }
  }

  get canAffordMakeup() {
    const cost = this.settings.makeup_cost_points || 0;
    return this.userPoints >= cost;
  }

  get makeupCost() {
    return this.settings.makeup_cost_points || 0;
  }

  get netGain() {
    const dailyPoints = this.settings.daily_points || 0;
    return dailyPoints - this.makeupCost;
  }

  get canPerformMakeup() {
    return this.selectedDate && this.canAffordMakeup && !this.loading;
  }

  get makeupEnabled() {
    return this.settings.makeup_enabled;
  }
}

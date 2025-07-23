import Controller from "@ember/controller";

export default Controller.extend({
  activeTab: "check-in",
  showSuccessMessage: false,
  successMessage: "",

  init() {
    this._super(...arguments);
    this.setupEventListeners();
  },

  setupEventListeners() {
    if (this.appEvents) {
      this.appEvents.on("check-in:success", this, this.onCheckInSuccess);
      this.appEvents.on("check-in:makeup-success", this, this.onMakeupSuccess);
      this.appEvents.on("check-in:error", this, this.onCheckInError);
    }
  },

  willDestroy() {
    this._super();
    if (this.appEvents) {
      this.appEvents.off("check-in:success", this, this.onCheckInSuccess);
      this.appEvents.off("check-in:makeup-success", this, this.onMakeupSuccess);
      this.appEvents.off("check-in:error", this, this.onCheckInError);
    }
  },

  actions: {
    switchTab(tabName) {
      this.set('activeTab', tabName);
    },

    hideMessage() {
      this.set('showSuccessMessage', false);
    }
  },

  onCheckInSuccess(data) {
    let message = `✅ ${I18n.t("check_in.success.checked_in")} +${data.pointsEarned} ${I18n.t("check_in.points")}`;

    if (data.bonusPoints > 0) {
      message += ` (${I18n.t("check_in.success.bonus_included", { points: data.bonusPoints })})`;
    }

    this.showMessage(message);
  },

  onMakeupSuccess(data) {
    const message = `✅ ${I18n.t("check_in.success.makeup_completed")} ${data.date} (+${data.pointsEarned}, -${data.makeupCost})`;
    this.showMessage(message);
  },

  onCheckInError(data) {
    this.showMessage(`❌ ${data.message}`, "error");
  },

  showMessage(message, type = "success") {
    this.setProperties({
      successMessage: message,
      showSuccessMessage: true
    });

    // Auto hide after 5 seconds
    setTimeout(() => {
      this.set('showSuccessMessage', false);
    }, 5000);
  },

  isCheckInTab: Ember.computed('activeTab', function() {
    return this.activeTab === 'check-in';
  }),

  isRecordsTab: Ember.computed('activeTab', function() {
    return this.activeTab === 'records';
  }),

  isMakeupTab: Ember.computed('activeTab', function() {
    return this.activeTab === 'makeup';
  })
});

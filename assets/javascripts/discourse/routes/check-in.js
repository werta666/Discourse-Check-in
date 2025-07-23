import DiscourseRoute from "discourse/routes/discourse";

export default DiscourseRoute.extend({
  beforeModel() {
    if (!this.currentUser) {
      this.transitionTo("login");
      return;
    }
  },

  model() {
    return {
      user: this.currentUser
    };
  },

  setupController(controller, model) {
    this._super(controller, model);
    controller.set("user", model.user);
  },

  titleToken() {
    return "check_in.page_title";
  }
});

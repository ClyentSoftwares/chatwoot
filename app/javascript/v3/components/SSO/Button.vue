<script>
import SimpleDivider from '../Divider/SimpleDivider.vue';
export default {
  components: {
    SimpleDivider,
  },
  props: {
    showSeparator: {
      type: Boolean,
      default: true,
    },
  },
  computed: {
    ssoName() {
      return window.ssoConfig.ssoName;
    },
  },
  methods: {
    redirectToAuthUrl() {
      const form = document.createElement('form');
      form.action = '/auth/openid_connect';
      form.method = 'POST';
      const token = document.createElement('input');
      token.name = 'authenticity_token';
      token.value = window.ssoConfig.authenticityToken;
      form.appendChild(token);
      document.body.appendChild(form);
      form.submit();
    },
  },
};
</script>

<template>
  <div class="flex flex-col">
    <button
      class="inline-flex w-full justify-center rounded-md bg-white py-3 px-4 shadow-sm ring-1 ring-inset ring-slate-200 dark:ring-slate-600 hover:bg-slate-50 focus:outline-offset-0 dark:bg-slate-700 dark:hover:bg-slate-700"
      @click="redirectToAuthUrl"
    >
      <span class="text-base font-medium ml-2 text-slate-600 dark:text-white">
        Sign in with {{ ssoName }}
      </span>
    </button>
    <SimpleDivider
      v-if="showSeparator"
      ref="divider"
      :label="$t('COMMON.OR')"
      class="uppercase"
    />
  </div>
</template>

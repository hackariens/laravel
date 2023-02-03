describe('template spec', () => {
  it('passes', () => {
    cy.visit('https://laravel.traefik.me', {failOnStatusCode: false});
    cy.screenshot('first-page');
  })
})